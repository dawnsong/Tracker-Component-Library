function demo2DDataAssociation()
%%DEMO2DDATAASSOCIATION Demonstrate how the Joint Probabilistic Data
%             Association Filter (JPDAF) and the GLobal Nearest Neighbor
%             (GNN)-JPDAF can be used when tracking a two target with the
%             possibility of missed detections and false alarms. Track
%             initiation and termination are not considered.
%
%A simple scenario of a ballistic target going from the Sea of Japan to
%an area in the middle of the Pacific (ignoring atmospheric drag, using a
%simple J2 model for the Earth's gravitational field is considered
%(ignoring light pressure and the gravitational attraction of other
%celestial bodies). Measurements are obtained by a radar in the Aleutian
%islands using a spherical measurement model. Refraction and other
%atmospheric effects are not simulated; Doppler is not used. Tracking and
%measurements are given in an Earth-centered Earth-fixed (ECEF) coordinate,
%system, requiring corrections for the Coriolis effect. Measurement-warping
%effects due to the Earth's rotation are not considered. 
%
%The true trajectories for simulation are created using the
%createBallisticTrajectories subroutine in this file. Measurements are
%assumed to be available when the target is above a certain elevation in
%the receiver's coordinate system. The elevation in the receiver's
%coordinate system is measured with respect to the local tangent plane to
%the WGS84 reference ellipsoid. The trajectories go from the Sea of Japan
%to the middle of the Pacific. The function orbVelDet2PtMinEng is used to
%get an approximate initial velocity for a minimum energy trajectory
%between the points. However, the function is only an approximation as it
%is meant for use in an Earth-centered-inertial coordiante system (thus
%trajectories are minimum energy ignoring the energy imparted by the
%rotation of the Earth. Additionally, the endpoints are specified in an
%ECEF coordinate system, so the initial conditions outputted by the
%function are only approximate (a ballistic projectile would miss its
%target due to the Earth's rotation). Additionally, atmospheric drag is
%not taken into account and the function assumes a Keplerian dynamic model.
%Thus, the results might be useful as initial estimates for a
%higher-fidelity trajectory estimation routine, but would be unsuitable for
%use on their own. For the purpose of this simulation, the trajectory is
%sufficiently realistic.
%
%To make two targets sufficiently close that they will contest
%measurements (making a JPDAF relevant), the second target's trajectory was
%set to be that of the first target, but with a 50m offset in range. The
%resulting trajectory is no longer truly ballistic, but is close enough for
%the simulation.
%
%The tracks are started using cubature integration and the orbVelDet2Pt
%function (which is for a Keplerian model, not a J2 model) via the
%CubatureLambertInit subroutine in this file. The correct measurements for
%two scans are used to start the tracks. After that, data association
%uncertainty can exist. This method of starting the tracks demonstrates how
%cubature integration can be used with an arbitrary dynamic model and
%measurement function to start a track. Note that additional steps would
%need to be taken if one were tracking satellites and multiple orbits
%between signtings were allowed , because the function orbVelDet2Pt would
%produce multiple solutions.
%
%The JPDAF and GNN-JPDAF algorithms require a likelihood matrix to
%make their (soft) associations of measurements to targets. The subroutine
%makeLRMat in this file creates the likelihood matrix based on the exponent
%of the  dimensionless score function of [1]. This requires that the
%clutter density in measurement space and the detection probability be
%known (or estimated). A nominal detection probability of 80% is used.
%
%The makeLRMat function also updates the tracks for each of the
%measurements. The sqrtKalmanUpdate function is used with
%Cartesian-converted measurements. The measurement conversion is performed
%using the spher2CartCubature function via fifth-order cubature
%integration.
%
%The target state is predicted usign the MomentMatchPred function, which
%can handle the nonlinear dynamic model. The MomentMatchPred function
%utilizes non-stochastic RUnge-Kutta methods to propagate the mean and
%square root covariance matrix.
%
%The trajectories are plotted along with the measurements. Also plotted is
%the offset from the range estimates of the target and the location of the
%first target. One could plot the mean squared error of the trajectories as
%well, but this is less informative regarding how well targets are
%separated as the cross-range errors for a monostatic tracking scenario
%such as this tend to be very high.
%
%[1] Y. Bar-Shalom, S. S. Blackman, and R. J. Fitzgerald, "Dimensionless
%score function for multiple hypothesis tracking," IEEE Transactions on
%Aerospace and Electronic Systems, vol. 43, no. 1, pp. 392-400, Jan. 2007.
%
%June 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

display('An example of simple nonlinear filtering and data association for a ballistic model') 

%%%SETUP THE MODEL
display('Setting parameters and creating the simulated trajectories.') 
PD=0.8;%Detection probability --same for all targets.
%The number of observations in the simulation.
numObs=100;

%Assumed clutter parameter in terms of false alarms per meter-radian^2
%(spherical coordinates). False alarms are generated in the measurement
%domain of the radar. The tracker can still work if the value for lambda
%does not perfectly match the value simulated/ the real value. However, one
%should note that lambda in the tracker cannot be arbitrarily large lest
%the tracker eventually ignore all measurements (false alarms become always
%more likely than true tracks).
lambda=1e-2;
numMethods=2;%2 filters, a JPDAF and an GNN-JPDAF.

%The AlgSel parameters are inputs to the singleScanUpdate function.
%Method 1 uses the JPDAF
algSel1(1)=1;
algSel2(1)=0;
%Method 2 uses the GNN-JPDAF
algSel1(2)=0;
algSel2(2)=0;

%The location of the simulated radar in the Aleutian islands.
posRx=[51.86310; -177.98669]*(pi/180);
rRx=ellips2Cart([posRx;0]);

%The continuous-time dynamic model.
rDot=@(rState,t)[rState(4:6,:);EGM08EarthAccel(rState)];

%Get the local coordinate axes of the receiver.
uENU=getENUAxes(posRx);

%Rotation matrix from global Cartesian coordinates to ENU
RGlob2ENU=findTransParam(eye(3,3),uENU);

%The nonlinear measurement function
h=@(x)Cart2Sphere(x(1:3,:),0,true,rRx,rRx,RGlob2ENU);

%Next, create the ballistic trajectories
[tObs,xObs,zObsTrue]=createBallisticTrajectories(rDot,h,numObs);
numTargets=size(zObsTrue,2);
PD=repmat(PD,[numTargets,1]);
zDim=size(zObsTrue,1);

%The time between samples is constant in this simulation, though missed
%detections are possible.
deltaT=tObs(2)-tObs(1);

sigmaR=10;
sigmaAzel=0.1*(pi/180);
%The square root measurement covariance matrix, local spherical
%coordiantes. Here, it is assumed diagonal.
SR=diag([sigmaR;sigmaAzel;sigmaAzel]);

%Region in range around the targets in which to generate false alarms.
clutR=50e3;%50km
%Angular region in which to generate random false alarms around the
%targets.
clutAngs=2*(pi/180);
%The volume used for generating false alarms based times the given false 
%alarm density is the expected number of false alarms per scan.
lambdaV=lambda*(2*clutR)*(2*clutAngs)^2;

%For measurement conversion
[xi3,w3]=fifthOrderCubPoints(3);

%For state propagation
[xi6,w6]=fifthOrderCubPoints(6);

%Initializations
q0=processNoiseSuggest('PolyKal-ROT',1e-2,deltaT);

a=rDot;
D=@(x,t)DPoly(x,t,q0,1,3);

H=[1,0,0,0,0,0;
   0,1,0,0,0,0;
   0,0,1,0,0,0];

display('Initializing the tracks.') 
%Generate the first two observations explicitly to start the tracks using an
%information filter. All methods get the same initialization.
xStates=zeros(6,numTargets,numObs,numMethods);
SStates=zeros(6,6,numTargets,numObs,numMethods);
zScans=cell(numObs,1);

zScans{1}=[];
zScans{2}=[];
zScansSpher{1}=[];
zScansSpher{2}=[];
for curTrack=1:numTargets
    z1=zObsTrue(:,curTrack,1)+SR*randn(3,1);
    [zCart1,RCart1]=spher2CartCubature(z1,SR,xi3,w3,0,true,rRx,rRx,RGlob2ENU);
    z2=zObsTrue(:,curTrack,2)+SR*randn(3,1);
    [zCart2,RCart2]=spher2CartCubature(z2,SR,xi3,w3,0,true,rRx,rRx,RGlob2ENU);

    zScansSpher{1}=z1;
    zScansSpher{2}=z2;
    
    [xInit,PInit]=CubatureLambertInit(z1,SR,z2,SR,RGlob2ENU,rRx,deltaT,xi6,w6);
    
    SInit=chol(PInit,'lower');
    
    for curMethod=1:numMethods
        xStates(:,curTrack,2,curMethod)=xInit;
        SStates(:,:,curTrack,2,curMethod)=SInit;
    end
    zScans{1}=[zScans{1},zCart1];
    zScans{2}=[zScans{2},zCart2];
end

display('Running the tracker simulation (this will take a little while).') 
%Run the tracker starting with the third measurement.
for curObs=3:numObs
    %Determine the number of false alarms to generate.
    numFalse=PoissonD.rand(1,lambdaV);
        
    %Determine which, if any, targets should be detected.
    isDet=rand(numTargets,1)<PD;
    
    %Allocate space for the detections.
    numMeas=numFalse+sum(isDet);
    zCur=zeros(3,numMeas);
    curDet=1;

    %Generate the detection from the targets, if any.
    for curTar=1:numTargets
        if(isDet(curTar)||curObs<5)
            zCur(:,curDet)=zObsTrue(:,curTar,curObs)+SR*randn(3,1);
            curDet=curDet+1;
        end
    end
    
    %Generate the false alarm detections, if any. They are centered around
    %the first target.
    rClutBounds=zObsTrue(1,1,curObs)+[-clutR;clutR];
    azBounds=zObsTrue(2,1,curObs)+[-clutAngs;clutAngs];
    elBounds=zObsTrue(3,1,curObs)+[-clutAngs;clutAngs];
    for curFalse=1:numFalse
        r=UniformD.rand(rClutBounds);
        az=UniformD.rand(azBounds);
        el=UniformD.rand(elBounds);
        
        zCur(:,curDet)=[r;az;el]+SR*randn(3,1);
        curDet=curDet+1;
    end

    %Convert all of the measurements to Cartesian coordinates using
    %cubature integration.
    zCart=zeros(zDim,numMeas);
    SRCart=zeros(zDim,zDim,numMeas);
    for curMeas=1:numMeas
        [zCart(:,curMeas),RCart]=spher2CartCubature(zCur(:,curMeas),SR,xi3,w3,0,true,rRx,rRx,RGlob2ENU);
        SRCart(:,:,curMeas)=chol(RCart,'lower');
    end
    zScans{curObs}=zCart;
    zScansSpher{curObs}=zCur;
    
    tPrev=tObs(curObs-1);
    tCur=tObs(curObs);
    
    %Update all of the tracks for the methods.
    for curMethod=1:numMethods
        %Predict the tracker to the current time for each target.
        x=xStates(:,:,curObs-1,curMethod);
        S=SStates(:,:,:,curObs-1,curMethod);
        for curTar=1:numTargets
            [x(:,curTar),S(:,:,curTar)]=MomentMatchPred(x(:,curTar),S(:,:,curTar),a,D,3,tPrev,tCur,xi6,w6);
        end

        %Brute-force hypothesis formation and likelihood matrix
        %computation. A is the likelihood matrix.
        [A,xHyp,PHyp]=makeLRMat(x,S,H,zCur,zCart,SRCart,PD,lambda);
        
        %Perform the single scan assignment
        [xPost,PPost]=singleScanUpdate(xHyp,PHyp,A,algSel1(curMethod),algSel2(curMethod));
        
        xStates(:,:,curObs,curMethod)=xPost;
        for curTar=1:numTargets
            SStates(:,:,curTar,curObs,curMethod)=chol(PPost(:,:,curTar),'lower');
        end        
    end
end

display('Plotting the measurements and tracks over the Earth.') 
%Indicates how the lines for the method are drawn.
methodStyle{1}='r';
methodStyle{2}='b';

%%%Plot the estimated trajectories on the true trajectory
figure(1)
clf
hold on
clf
plotMapOnEllipsoid();
hold on;

%Plot all of the measurements for all of the scans
for curObs=1:numObs
    zCur=zScans{curObs};
    scatter3(zCur(1,:),zCur(2,:),zCur(3,:),'.b')
end

%Plot the tracks
plot3(xObs(1,:),xObs(2,:),xObs(3,:),'-g','linewidth',4)
for curMethod=1:numMethods
    %Track 1 is drawn in red; track 2 is drawn in blue.
    for curTrack=1:numTargets
        if(curTrack==1)
            lineOpts=['-',methodStyle{curMethod}];
        else
            lineOpts=['--',methodStyle{curMethod}];
        end

        x=xStates(:,curTrack,:,curMethod);
        plot3(x(1,2:end),x(2,2:end),x(3,2:end),lineOpts,'LineWidth',2)
    end
end

display('Plotting the offset in range of the track estimates from the first target.')
display('The lines for track 1 are solid; those for track 2 are dashed.')
display('JPDAF estimates are red; GNN estimates are blue.')
display('The observations are shown in black. The estimates are relatively close to the observations.')
%%%Compute and then plot the offset in range from the primary target.
rErrTargets=zeros(numObs,numTargets,numMethods);
for curObs=2:numObs
    for curMethod=1:2 
        for curTrack=1:numTargets
            xState=xStates(:,curTrack,curObs,curMethod);
            SState=SStates(:,:,curTrack,curObs,curMethod);
            r=unbiasedR(xState,SState,RGlob2ENU,rRx,xi6,w6);
            
            rErrTargets(curObs,curTrack,curMethod)=r-zObsTrue(1,1,curObs);
        end
    end
end

figure(3)
clf
hold on
for curMethod=1:numMethods
    %Track 1 is drawn in red; track 2 is drawn in blue.
    for curTrack=1:numTargets
        if(curTrack==1)
            lineOpts=['-',methodStyle{curMethod}];
        else
            lineOpts=['--',methodStyle{curMethod}];
        end

        r=rErrTargets(:,curTrack,curMethod);
        plot(tObs(2:end),r(2:end),lineOpts,'LineWidth',2)
    end
end

%Plot the range of all of the measurements for all of the scans too
for curObs=2:numObs
    zCur=zScansSpher{curObs};
    numObs=size(zCur,2);
    if(numObs>0)
        scatter(repmat(tObs(curObs),[numObs,1]),bsxfun(@minus,zCur(1,:),zObsTrue(1,1,curObs)),'.k');
    end
end

h1=xlabel('Time (seconds)');
h2=ylabel('Offset in Range (meters)');

set(gca,'FontSize',18,'FontWeight','bold','FontName','Times')
set(h1,'FontSize',20,'FontWeight','bold','FontName','Times')
set(h2,'FontSize',20,'FontWeight','bold','FontName','Times')
axis([tObs(2), tObs(end), -300, 300])

end

function [A,xHyp,PHyp]=makeLRMat(xPred,SPred,H,zSpher,zCart,SRCart,PD,lambda)
%%We are using the dimensionless score function from 
%Y. Bar-Shalom, S. S. Blackman, and R. J. Fitzgerald, "Dimensionless score
%function for multiple hypothesis tracking," IEEE Transactions on Aerospace
%and Electronic Systems, vol. 43, no. 1, pp. 392-400, Jan. 2007.

xDim=size(xPred,1);
zDim=size(zCart,1);
numTar=size(xPred,2);
numMeas=size(zCart,2);
numHyp=numMeas+1;%The extra one is the missed detection hypothesis.

A=zeros(numTar,numMeas+numTar);
xHyp=zeros(xDim,numTar,numHyp);
PHyp=zeros(xDim,xDim,numTar,numHyp);

for curTar=1:numTar
    xPredCur=xPred(:,curTar);
    SPredCur=SPred(:,:,curTar);

    for curMeas=1:numMeas
        zSpherCur=zSpher(:,curMeas);
        zCartCur=zCart(:,curMeas);
        SRCartCur=SRCart(:,:,curMeas);
        [xUpdate, SUpdate,innov,Szz]=sqrtKalmanUpdate(xPredCur,SPredCur,zCartCur,SRCartCur,H);
        xHyp(:,curTar,curMeas)=xUpdate;
        PHyp(:,:,curTar,curMeas)=SUpdate*SUpdate';
        
        %The clutter density lambda is given in terms of SPHERICAL
        %coordinates. To LOCALLY convert it to CARTESIAN coordinates, we
        %have to multiply it by the determinant of the Jacobian.
        J=calcSpherJacob(zSpherCur,0);
        A(curTar,curMeas)=PD(curTar)/(det(J)*lambda)*GaussianD.PDFS(innov,zeros(zDim,1),Szz);
    end
    
    %The missed detection likelihood.
    A(curTar,numMeas+curTar)=(1-PD(curTar));
    xHyp(:,curTar,end)=xPredCur;
    PHyp(:,:,curTar,end)=SPredCur*SPredCur';
end
end

function [tObs,xObs,zObsTrue]=createBallisticTrajectories(rDot,h,numObs)
    posStart=([39.61693; 134.54975])*pi/180;%The Sea of Japan
    %The middle of the Pacific.
    posEnd=([40.56751; -159.53953])*pi/180;
    rStart=ellips2Cart([posStart;0]);
    rEnd=ellips2Cart([posEnd;0]);

    minEL=10*(pi/180);%Minimum elevation for tracking.

    %Get starting velocity
    [vStart,tMinEllip]=orbVelDet2PtMinEng(rStart,rEnd);
    tSpan=[0; tMinEllip*1.25];

    %The function RKAdaptiveOverRange could be used to integrate over the
    %trajectory to a higher polynomial accuracy, but it is simpler to use
    %ode45, because the interpolation routine deval for the solution is
    %easy to use to get observations at desired times.
    options=odeset('RelTol',1e-8,'AbsTol',1e-10,'Refine',20);
    [tFull,xFull]=ode45(@(t,rState) rDot(rState,t),tSpan,[rStart;vStart],options);
    xFull=xFull';

    %Noise-free observations in the local coordinate system of the receiver.
    zTrue=h(xFull(1:3,:));
    elIdx=find(zTrue(3,:)>minEL);

    %Allocate space depending on the chosen scenario.
    zObsTrue=zeros(3,2,numObs);%The main target and one other return.
    
    %Get the primary trajectory at desired times
    tObs=linspace(tFull(elIdx(1)),tFull(elIdx(end)),numObs);
    options=odeset('RelTol',1e-8,'AbsTol',1e-10);
    sol=ode45(@(t,rState) rDot(rState,t),tSpan,[rStart;vStart],options);
    xObs=deval(sol,tObs);
    zObsTrue(:,1,:)=h(xObs(1:3,:));
    
    %The second target is offset by a constant amount in range.
    zObsTrue(2:end,2,:)=zObsTrue(2:end,1,:);
    zObsTrue(1,2,:)=zObsTrue(1,1,:)+50;
end

function [xInit,PInit]=CubatureLambertInit(z1,SR1,z2,SR2,RGlob2ENU,rRx,deltaT,xi6,w6)
    zStacked=[z1;z2];
    SStacked=blkdiag(SR1,SR2);
    numCubPoints=length(w6);
    
    %Transform the cubature points to the joint distribution of the
    %measurements.
    xiTrans=transformCubPoints(xi6,zStacked,SStacked);
    
    %Convert the transformed cubature points into global ECEF Cartesian
    %coordinates.
    r1Val=spher2Cart(xiTrans(1:3,:),0,true,rRx,rRx,RGlob2ENU);
    r2Val=spher2Cart(xiTrans(4:6,:),0,true,rRx,rRx,RGlob2ENU);
   
    %Solve Lambert's problem --the results will be in cell arrays, but
    %there will only be one solution per cubature point (assuming nothing
    %failed), so we can convert them directly into matrices.
    isECEF=true;
    [~,V2Comp]=orbVelDet2Pt(r1Val,r2Val,deltaT,0,isECEF,false);
    V2Comp=reshape(cell2mat(V2Comp),[3,numCubPoints]);
    
    %Get the moments of the points to return
    [xInit, PInit]=calcMixtureMoments([r2Val;V2Comp],w6);
end

function r=unbiasedR(xState,SState,RGlob2ENU,rRx,xi,w)
    %Get an unbiased conversion of a Cartesian state into a range to a
    %sensor using cubature conversion (ignoring all propagation effects).
    
    %Transform the cubature points.
    xi=bsxfun(@plus,SState*xi,xState);

    %Subtract the receiver location and rotate into ENU coordinates.
    xiLocal=RGlob2ENU*bsxfun(@minus,xi(1:3,:),rRx);
    
    %Compute ranges
    rCub=sqrt(sum(xiLocal(1:3,:).^2,1));
    r=sum(bsxfun(@times,rCub(:),w(:)));
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
