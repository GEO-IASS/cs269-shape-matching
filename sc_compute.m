function [BH,mean_dist]=sc_compute(xy_samples,theta_samples,mean_dist,nbins_theta,nbins_r,r_bin_hist_start,r_bin_hist_end,out_vec);
% [BH,mean_dist]=sc_compute(Bsamp,Tsamp,mean_dist,nbins_theta,nbins_r,r_inner,r_outer,out_vec);
%
% compute (r,theta) histograms for points along boundary 
%
% Bsamp isan 2 x nsamp (x d y coords.)
% Tsamp is 1 x nsamp (tangent theta)
% out_vec is 1 x nsamp (0 for inlier, 1 for outlier)
%
% mean_dist is the mean distance, used for length normalization
% if it is not supplied, then it is computed from the data
%
% outliers are not counted in the histograms, but they do get
% assigned a histogram
%

nsamp=size(xy_samples,2);
in_vec = out_vec==0;

% compute r,theta arrays
radial_distance_array = real(sqrt(eucledianDistMatrix(xy_samples',xy_samples')));                                          
theta_array_abs = atan2(xy_samples(2,:)'*ones(1,nsamp)-ones(nsamp,1)*xy_samples(2,:),xy_samples(1,:)'*ones(1,nsamp)-ones(nsamp,1)*xy_samples(1,:))';
theta_array = theta_array_abs-theta_samples'*ones(1,nsamp);

% create joint (r,theta) histogram by binning r_array and theta_array

% normalize distance by mean, ignoring outliers
if isempty(mean_dist)
   tmp=radial_distance_array(in_vec,:);
   tmp=tmp(:,in_vec);
   mean_dist=mean(tmp(:));
end
r_array_normalized = radial_distance_array/mean_dist;

% use a log. scale for binning the distances
r_bin_hist_edges = logspace(log10(r_bin_hist_start),log10(r_bin_hist_end),nbins_r);
r_array_hist_count = zeros(nsamp,nsamp);
for m=1:nbins_r
   r_array_hist_count = r_array_hist_count+(r_array_normalized<r_bin_hist_edges(m));
end
fz=r_array_hist_count>0; % flag all points inside outer boundary

% put all angles in [0,2pi) range (angles here maybe negative, which is why
% we just simply don't mod by 2pi
theta_array_2 = rem(rem(theta_array,2*pi)+2*pi,2*pi);
% quantize to a fixed set of angles (bin edges lie on 0,(2*pi)/k,...2*pi
% Divide the theta_array by 30 degrees (30 is derived from dividing 360
% degrees into 12 bins) to find bin index into which that particular theta
% falls into.
theta_array_q = 1+floor(theta_array_2/(2*pi/nbins_theta));

nbins=nbins_theta*nbins_r;
BH=zeros(nsamp,nbins);
for n=1:nsamp
   fzn=fz(n,:)&in_vec;
   %Find out what this does
   Sn=sparse(theta_array_q(n,fzn),r_array_hist_count(n,fzn),1,nbins_theta,nbins_r);
   BH(n,:)=Sn(:)';
end




