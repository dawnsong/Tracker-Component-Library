function z=state2SpherRR(xTar,systemType,useHalfRange,xTx,xRx,M)
%%STATE2SPHERRR Convert state vectors consisting of at least 3D position
%               and velocity in 3D space into local spherical coordinates
%               with non-relativistic range rate. An option allows for the
%               angles to be specified from different axes. Optionally, a
%               bistatic range can be used when considering bistatic
%               measurements in a local spherical coordinate system.
%
%INPUTS:    xTar A xDimXN matrix of N target states consisting of 3D
%                position and velocity components in the order
%                xTar=[xPosition;xVelocity] and possible other components,
%                which will be ignored.
%        systemType An optional parameter specifying the axes from which
%                   the angles are measured. Possible vaues are
%                   0 (The default if omitted) Azimuth is measured
%                     counterclockwise from the x-axis in the x-y plane.
%                     Elevation is measured up from the x-y plane (towards
%                     the z-axis). This is consistent with common spherical
%                     coordinate systems for specifying longitude (azimuth)
%                     and geocentric latitude (elevation).
%                   1 Azimuth is measured counterclockwise from the z-axis
%                     in the z-x plane. Elevation is measured up from the
%                     z-x plane (towards the y-axis). This is consistent
%                     with some spherical coordinate systems that use the z
%                     axis as the boresight direction of the radar.
%   useHalfRange A boolean value specifying whether the bistatic range
%                value should be divided by two. This normally comes up
%                when operating in monostatic mode, so that the range
%                reported is a one-way range. The default if this parameter
%                is not provided is true.
%           xTx  An xTxDimXN matrix of the states of the transmitters
%                consisting of stacked 3D position and velocity components.
%                Other components will be ignored. If this parameter is
%                omitted, the transmitters are assumed to be stationary at
%                the origin. If only a single vector is passed, then the
%                transmitter state is assumed the same for all of the
%                target states being converted.
%           xRx  An xRxDimXN matrix of the states of the receivers
%                consisting of stacked 3D position and velocity components.
%                Other components will be ignored. If this parameter is
%                omitted, the receivers are assumed to be stationary at
%                the origin. If only a single vector is passed, then the
%                receiver state is assumed the same for all of the target
%                states being converted.
%           M    A 3X3XN hypermatrix of the rotation matrices to go from 
%                the alignment of the global coordinate system to that at
%                the receiver. The z-axis of the local coordinate system
%                of the receiver is the pointing direction of the receiver.
%                If omitted, then it is assumed that the local coordinate
%                system is aligned with the global and M=eye(3) --the
%                identity matrix is used. If only a signle 3X3 matrix is
%                passed, then is is assumed to be the same for all of the
%                N conversions.
%
%OUTPUTS: z   A 4XN matrix of the target states in xTar converted into
%             bistatic spherical and bistatic range rate coordinates. If
%             useHalfRange=true, then the r component is half the bistatic
%             range and the range rate is correspondingly halved.
%
%Details of the conversions are given in [1].
%
%REFERENCES:
%[1] D. F. Crouse, "Basic tracking using nonlinear 3D monostatic and
%    bistatic measurements," IEEE Aerospace and Electronic Systems
%    Magazine, vol. 29, no. 8, Part II, pp. 4?53, Aug. 2014.
%
%October 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

N=size(xTar,2);

if(nargin<6)
    M=repmat(eye(3),[1,1,N]);
elseif(size(M,3)==1)
    M=repmat(M,[1,1,N]);
end

if(nargin<5)
    xRx=zeros(6,N);
elseif(size(xRx,2)==1)
    xRx=repmat(xRx,[1,N]);
end

if(nargin<4)
    xTx=zeros(6,N);
elseif(size(xTx,2)==1)
    xTx=repmat(xTx,[1,N]);
end

if(nargin<3)
   useHalfRange=true; 
end

if(nargin<2)
    systemType=0;
end

%Allocate space for the converted states.
z=zeros(4,N);

%Convert the positions.
z(1:3,:)=Cart2Sphere(xTar(1:3,:),systemType,useHalfRange,xTx(1:3,:),xRx(1:3,:),M);

%Compute the bistatic range rates.
z(4,:)=getRangeRate(xTar,useHalfRange,xTx,xRx);
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
