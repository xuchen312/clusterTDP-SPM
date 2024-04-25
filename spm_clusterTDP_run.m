%-Compute xSPM
%----------------------------------------------------------------------
[SPM,xSPM] = spm_getSPM;

%-Extract data from xSPM
%----------------------------------------------------------------------
xyzs = xSPM.XYZ';
dims = xSPM.DIM';
mat  = xSPM.M;
zval = xSPM.Z;
kval = xSPM.uc(3);

%-Find clusters
%----------------------------------------------------------------------
[clus,stat] = deal(zeros(dims));
for i=1:size(xyzs,1)
    clus(xyzs(i,1),xyzs(i,2),xyzs(i,3)) = 1;
    stat(xyzs(i,1),xyzs(i,2),xyzs(i,3)) = zval(i);
end
[L,NUM] = spm_bwlabel(clus);

%-Compute lower bound of TDN lower bound for each cluster
%----------------------------------------------------------------------
[sz,lb,mz] = deal(zeros(NUM,1));
for i=1:NUM
    sz(i) = sum(L(:)==i);                            % 1) cluster size

    [x,y,z] = ind2sub(dims,find(L==i));
    %lb(i) = spm_clusterTDP_lb([x y z],ceil(kval));
    lb(i) = spm_clusterTDP_lb([x y z],round(kval));  % 2) TDN lower bound

    mz(i) = max(stat(L(:)==i));                      % 3) max(T)
end

%-Sort local maxima in descending order
%----------------------------------------------------------------------
[mz,I] = sort(mz,'descend');
sz = sz(I);
lb = lb(I);
tdp = lb./sz;                                        % 4) TDP lower bound

%-Workaround in spm_max for conjunctions with negative thresholds
%----------------------------------------------------------------------
[clusSz,maxZ,maxXYZ,regs,XYZ] = spm_max(zval,xyzs');

% sort local maxima in descending order
[maxZ,I] = sort(maxZ,'descend');
clusSz   = clusSz(I);
maxXYZ   = maxXYZ(:,I);
regs     = regs(I);
% return unique values of regs (unsorted)
[~,I,~] = unique(regs,'stable');
clusSz   = clusSz(I);                                % 1) cluster size
maxZ     = maxZ(I);                                  % 3) max(T)
maxXYZ   = maxXYZ(:,I);                              % 5) XYZ coordinates
maxXYZmm = mat(1:3,:)*[maxXYZ; ones(1,size(maxXYZ,2))];

fprintf('\n');

% create result table
tbl = table(sz,lb,tdp,mz,maxXYZmm');
tbl.Properties.Description   = 'Statistics: cluster-level summary for search volume';
tbl.Properties.RowNames      = string(1:length(sz));
tbl.Properties.VariableNames = {'Cluster size','TDN','TDP','max(T)','[X,Y,Z]'};
tbl.('TDP')    = round(tbl.('TDP'),3);
tbl.('max(T)') = round(tbl.('max(T)'),3);
fprintf('Statistics: cluster-level summary for search volume\n')
disp(tbl);

% write result table to a text file
writetable(tbl,'clusTbl.txt','Delimiter',' ','WriteRowNames',true); 






