function [xPred, PPred]=discKalPred(xPrev,PPrev,F,Q,u)
%DISCKALPRED Perform the discrete-time prediction step that comes with 
%            the standard linear Kalman filter with additive Gaussian
%            process noise.
%
%INPUTS:    xPrev   The xDim X 1 state estimate at the previous time-step.
%           PPrev   The xDim X xDim state covariance matrix at the previous
%                   time-step.
%           F       An xDim X xDim state transition matrix.
%           Q       The xDimX xDim process noise covariance matrix.
%           u       An optional xDim X1 vector that is the control input.
%                   If omitted, no control input is used.
%
%OUTPUTS:   xPred   The xDim X 1 predicted state estimate.
%           PPred   The xDim X xDim predicted state covariance matrix.
%
%The algorithm is derived in Chapter 5 of [1].
%
%REFERENCES:
%[1] Y. Bar-Shalom, X. R. Li, and T. Kirubarajan, Estimation with
%    Applications to Tracking and Navigation. New York: John Wiley and
%    Sons, Inc, 2001.
%
%October 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

if(nargin<5)
   u=0; 
end

xPred=F*xPrev+u;
PPred=F*PPrev*F'+Q;
end

%LICENSE:
%
%The source code is in the public domain and not licensed or under
%copyright. The information and software may be used freely by the public.
%As required by 17 U.S.C. 403, third parties producing copyrighted works
%consisting predominantly of the material produced by U.S. government
%agencies must provide notice with such work(s) identifying the U.S.
%Government material incorporated and stating that such material is not
%subject to copyright protection.
%
%Derived works shall not identify themselves in a manner that implies an
%endorsement by or an affiliation with the Naval Research Laboratory.
%
%RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF THE
%SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY THE NAVAL
%RESEARCH LABORATORY FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE ACTIONS
%OF RECIPIENT IN THE USE OF THE SOFTWARE.
