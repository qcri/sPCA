function [C, ss, M, X,Ye] = ppca_mv(Ye,d,dia)
%
% implements probabilistic PCA for data with missing values, 
% using a factorizing distribution over hidden states and hidden observations.
%
%  - The entries in Ye that equal NaN are assumed to be missing. - 
%
% [C, ss, M, X, Ye ] = ppca_mv(Y,d,dia)
%
% Y   (N by D)  N data vectors
% d   (scalar)  dimension of latent space
% dia (binary)  if 1: printf objective each step
%
% ss  (scalar)  isotropic variance outside subspace
% C   (D by d)  C*C' +I*ss is covariance model, C has scaled principal directions as cols.
% M   (D by 1)  data mean
% X   (N by d)  expected states
% Ye  (N by D)  expected complete observations (interesting if some data is missing)
%
% J.J. Verbeek, 2006. http://lear.inrialpes.fr/~verbeek
%

[N D]       = size(Ye); % N observations in D dimensions
threshold   = 1e-4;     % minimal relative change in objective funciton to continue    
hidden      = isnan(Ye); 
missing     = sum(hidden(:));

M = zeros(1,D);  % compute data mean and center data
if missing; 
    for i=1:D;  
        M(i) = mean(Ye(~hidden(:,i),i)); 
    end;
else
    M    = mean(Ye);                 
end;
Ye = Ye - repmat(M,N,1);

if missing
    Ye(hidden)=0; 
end

Ye(1:5,1:10)
% =======     Initialization    ======
rand("seed",0)
C     = rand(D,d);
traceC=trace(C)
CtC   = C'*C;
tracectc=trace(CtC)
tracectc=trace(inv(CtC))
traceY=trace(Ye)
X     = Ye * C * inv(CtC);
traceX=trace(X)
recon = X*C'; recon(hidden) = 0;
tracerec=trace(recon)
ss    = sum(sum((recon-Ye).^2)) / (N*D-missing);
ss

count = 1; 
old   = Inf;
while count          %  ============ EM iterations  ==========      
   
    Sx = inv( eye(d) + CtC/ss );    % ====== E-step, (co)variances   =====
	 traceSx = trace(Sx)
    ss_old = ss;
    if missing
        proj = X*C'; 
        Ye(hidden) = proj(hidden); 
    end  
    X = Ye*C*(Sx/ss);          % ==== E step: expected values  ==== 
	 traceX = trace(X)
    
    SumXtX = X'*X;                              % ======= M-step =====
	 tracesumxtx=trace(SumXtX)
    C      = (Ye'*X)  / (SumXtX + N*Sx );    
	 tarceC=trace(C)
    CtC    = C'*C;
	 traceCtC=trace(CtC)
    ss     = ( sum(sum( (X*C'-Ye).^2 )) + N*sum(sum(CtC.*Sx)) + missing*ss_old ) /(N*D); 
    
    objective = N*D + N*(D*log(ss) +trace(Sx)-log(det(Sx)) ) +trace(SumXtX) -missing*log(ss_old);           
           
    rel_ch    = abs( 1 - objective / old );
    old       = objective;
    
    count = count + 1;
    if ( rel_ch < threshold) && (count > 5); count = 0;end
    if dia; fprintf('Objective:  %.2f    relative change: %.5f \n',objective, rel_ch ); end
    
end             %  ============ EM iterations  ==========



%C = orth(C);
%X = Ye*C; 
%Ye = X * C';

%C = orth(C);
%[vecs,vals] = eig(cov(Ye*C));
%[vals,ord] = sort(diag(vals),'descend');
%vecs = vecs(:,ord);
%C = C*vecs;
%X = Ye*C;
 
%[c, ~, ~] = svd(C);
%X = Ye * c(:,1:d);
%[u, ~ ,~] = svd(X');
%X = X*u;



% add data mean to expected complete data
Ye = Ye + repmat(M,N,1);
