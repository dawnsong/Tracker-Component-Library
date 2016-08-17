classdef BinomialD
%Functions to handle the binomial distribution.
%Implemented methods are: mean, var, PMF, CDF, rand
%
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

methods(Static)

function val=mean(n,p)
%%MEAN  Obtain the mean of the binomial distribution for the given number
%       of trials and probability of success.
%
%INPUTS: n  The number of trials performed.
%        p  The probability of success for the underlying Bernoulli trials.
%           0<=p<=1.
%
%OUTPUTS: val  The mean number of successes for the binomial distribution.
%
%October 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.

    val=n*p;
end

function val=var(n,p)
%%VAR   Obtain the variance of the binomial distribution for the given
%       number of trials and probability of success.
%
%INPUTS: n  The number of trials performed.
%        p  The probability of success for the underlying Bernoulli trials.
%           0<=p<=1.
%
%OUTPUTS: val  The variance of the binomial distribution with the given
%              parameters.
%
%October 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.

    val=n*p*(1-p);
end

function val=PMF(k,n,p)
%%PMF         Evaluate the binomial probability mass function at a given
%             point with a specified number of trials and success
%             probability per trial.
%
%INPUTS: k  The nonnegative integer point(s) at which the binomial PMF is
%           to be evaluated (the number of successes in n trials). Note
%           that 0<=k<=n.
%        n  The number of trials of which k successes are observed.
%        p  The probability of success for the underlying Bernoulli trials.
%           0<=p<=1.
%
%OUTPUT: val The value(s) of the binomial PMF with success probability p.
%
%The binomial PMF provides the probability of k successes from n trials,
%each with a success probability of p.
%
%September 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.

    numPoints=length(k);
    val=zeros(size(k));
    for curK=1:numPoints
        val(curK)=binomial(n,k(curK))*p^k(curK)*(1-p)^(n-k(curK));
    end
end

function val=CDF(k,n,p)
%%CDF         Evaluate the cumulative distribution function of the
%             binomial distribution at a desired point.
%
%INPUTS: k  The nonnegative integer point(s) at which the binomial CDF is
%           to be evaluated. Note that 0<=k<=n.
%        n  The number of trials of which k or fewer successes are
%           observed.
%        p  The probability of success for the underlying Bernoulli trials.
%           0<=p<=1.
%
%OUTPUTS: val  The CDF of the binomial distribution evaluated at the
%              desired point(s).
%
%Rather than summing over the values of the PMF, the equivalency between
%the binomial distribution and the regularized incomplete beta function,
%described at [1] is used. Thus, the built-in function betainc can be used
%for efficient evaluation of the CDF with large values.
%
%REFERENCES:
%[1] Weisstein, Eric W. "Binomial Distribution." From MathWorld--A Wolfram
%    Web Resource. http://mathworld.wolfram.com/BinomialDistribution.html
%
%September 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.

    val=betainc(1-p,n-k,k+1);
end
    
function vals=rand(N,n,p)
%%RAND Generate binomial random variables with a given number of trials and
%      probability of success.
%
%INPUTS:    N  If N is a scalar, then rand returns an NXN matrix of random
%              variables. If N=[M,N1] is a two-element row  vector, then
%              rand returns an MXN1 matrix of random variables.
%           n  The number of trials performed.
%           p  The probability of success for the underlying Bernoulli 
%              trials. 0<=p<=1.
%
%The algorithm used depends on the value of n*min(p,1-p). If
%n*min(p,1-p)>=10, then the binomial, triangle, parallelogram, exponential
%algorithm of [1] is used. If n*min(p,1-p)<10, then a basic inverse
%transformation method, as described in [1] is used. This assures that the
%random number generation is fast for a wide variety of values of n and p.
%
%REFERENCES:
%[1] V. Kachitvichyanukul and B. W. Schmeiser, "Binomial random variate
%    generation," Communications of the ACM, vol. 31, no. 2, pp. 216-222,
%    Feb. 1988.
%
%August 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.

    if(isscalar(N))
        dims=[N N];
    else
        dims=N;
    end

    vals=zeros(dims);
    numVals=numel(vals);

    %Do not use the BTPE algorithm if n*min(p,1-p) is small. Rather, the
    %inverse transformation algorithm from Section 2 is used. However, it
    %has been modified replacing p with pMin=min(p,1-p) as described in the
    %text to reduce the execution time.
    if(n*min(p,1-p)<10)
        pMin=min(p,1-p);
        q=1-pMin;
        s=pMin/q;
        a=(n+1)*s;
        
        for curVal=1:numVals
            u=rand(1);
            r=q^n;
            x=0;
            gotoNextVal=false;
            
            %With n*pMin<10, the mean of the PMF is below 10 and the
            %standard deviation is below sqrt(10). To assure a limited
            %runtime, we thus cap the maximum value of the iterated x at
            %1000, or about 316 standard deviations from the mean.
            while(x<1000)
                if(u<=r)
                    %This part deals with using pMin instead of p.
                    if(p>1/2)
                        x=n-x;
                    end
                    vals(curVal)=x;
                    gotoNextVal=true;
                    break;
                end
                u=u-r;
                x=x+1;
                r=((a/x)-s)*r;
            end
            
            if(gotoNextVal)
                continue;
            end
            
            if(p>1/2)
                x=n-x;
            end
            vals(curVal)=x;
        end
        return;
    end

%If we are here, then the BTPE algorithm should be used. Everything below
%is the BTPE algorithm from Section 3 of [1].
    
%Step 0: Set up constants as functions of n and p.
    r=min(p,1-p);
    q=1-r;
    fM=n*r+r;
    M=floor(fM);
    p1=floor(2.195*sqrt(n*r*q)-4.6*q)+0.5;
    xM=M+0.5;
    xL=xM-p1;
    xR=xM+p1;
    c=0.134+20.5/(15.3+M);
    a=(fM-xL)/(fM-xL*r);
    lambdaL=a*(1+a/2);
    a=(xR-fM)/(xR*q);
    lambdaR=a*(1+a/2);
    p2=p1*(1+2*c);
    p3=p2+c/lambdaL;
    p4=p3+c/lambdaR;
    
    for curVal=1:numVals
        gotoNextVal=false;
        while(1)
            if(gotoNextVal)
                break;
            end
            
    %Step 1: Generate a random variable for selecting the region. If region
    %   1 is selected, generate a triangularly distributed random variable.
            u=rand(1)*p4;
            v=rand(1);
            if(u<p1)%Generate a triangular variate.
                y=floor(xM-p1*v+u);
                if(p>1/2)%Step 6
                    y=n-y;
                end
                vals(curVal)=y;
                gotoNextVal=true;
                continue;
            elseif(u<=p2)%Step 2: Parallelograms.
                x=xL+(u-p1)/c;
                v=v*c+1-abs(M-x+0.5)/p1;
                if(v<=0||v>1)
                    continue;
                end

                y=floor(x);
            elseif(u<=p3)%Step 3: Left exponential tail.
                y=floor(xL+log(v)/lambdaL);
                if (y<0)
                    continue;
                end
                v=v*(u-p2)*lambdaL;
            else%Step 4: Right exponential tail.
                y=floor(xR-log(v)/lambdaR);
                if(y>n)
                    continue;
                end
                v=v*(u-p3)*lambdaR;
            end
        
    %Step 5: Acceptace/ Rejection Comparison.

            k=abs(y-M);
        %5.0 Test for appropriate method of evaluating f(y)
            if(k<=20||k>=n*r*q/2-1)
                %5.1 Evaluate f(y) via recursive relationship
                s=r/q;
                a=s*(n+1);
                F=1;
                if(M<y)
                    i=M;
                    while(1)
                        i=i+1;
                        F=F*(a/i-s);
                        if(i==y)
                            break;
                        end
                    end
                elseif(M>y)
                    i=y;
                    while(1)
                       i=i+1;
                       F=F/(a/i-s);
                       if(i==M)
                           break;
                       end
                    end
                end

                if(v<=F)
                    if(p>1/2)%Step 6
                        y=n-y;
                    end
                    vals(curVal)=y;
                    gotoNextVal=true;
                    continue;
                else
                    continue;
                end
            else
                %5.2 Test for squeezing. Check the value of ln(v) against
                %upper and lower bounds of ln(f(y))
                rho=(k/(n*r*q))*((k*(k/3+0.625)+(1/6))/(n*r*q)+0.5);
                t=-k^2/(2.0*n*r*q);
                A=log(v);
                if(A<t-rho)
                    if(p>1/2)%Step 6
                        y=n-y;
                    end
                    vals(curVal)=y;
                    gotoNextVal=true;
                    continue;
                elseif(A>t+rho)
                    continue;
                end
            %5.3 Final Acceptance/ Rejection Test
                x1=y+1;
                f1=M+1;
                z=n+1-M;
                w=n-y+1;
                x2=x1^2;
                f2=f1^2;
                z2=z^2;
                w2=w^2;

                temp=xM*log(f1/x1)+(n-M+0.5)*log(z/w) ...
                +(y-M)*log(w*r/(x1*q)) ...
                +(13860-(462-(132-(99 ...
                -140/f2)/f2)/f2)/f2)/f1/166320 ...
                +(13860-(462-(132-(99 ...
                -140/z2)/z2)/z2)/z2)/z/166320 ...
                +(13860-(462-(132-(99 ...
                -140/x2)/x2)/x2)/x2)/x1/166320 ...
                +(13860-(462-(132-(99 ...
                -140/w2)/w2)/w2)/w2)/w/166320;
                if(A<=temp)
                    if(p>1/2)%Step 6
                        y=n-y;
                    end
                    vals(curVal)=y;
                    gotoNextVal=true;
                    continue;
                else
                    continue;
                end
            end
        end
    end
end

end
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
