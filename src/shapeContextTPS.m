%Compute correspondence and alignment transform for each iteration
while warping
    disp(['iter=' int2str(current_iteration)])
    
    %Compute shape contexts for shape 1
    [shapeContextHistogram1,mean_dist_1]=computeAlignmentTransform(contour_1',zeros(1,nsamp),mean_dist_global,nbins_theta,nbins_r,r_inner,r_outer,out_vec_1);     
    %Compute shape contexts for shape 2
    disp('computing shape contexts for target...')        
    [BshapeContextHistogram2,mean_dist_2]=computeAlignmentTransform(contour_2',zeros(1,nsamp),mean_dist_global,nbins_theta,nbins_r,r_inner,r_outer,out_vec_2);   
    
        if current_iteration==1
                lambda_o=1000;
        else
            lambda_o=beta_init*r^(current_iteration-2);	 
        end
        beta_k=(mean_dist_2^2)*lambda_o;

    
    costmat_shape=hist_cost_2(shapeContextHistogram1,BshapeContextHistogram2);
    theta_diff=repmat(shape_1_theta,1,nsamp)-repmat(shape_2_theta',nsamp,1);
    
    costmat_theta=0.5*(1-cos(theta_diff));
    costmat=(1-ori_weight)*costmat_shape+ori_weight*costmat_theta;
    
    nptsd=nsamp+ndum;
    costmat2=eps_dum*ones(nptsd,nptsd);
    costmat2(1:nsamp,1:nsamp)=costmat;
    cvec=hungarian(costmat2);
    
    
    [a,cvec2]=sort(cvec);
    out_vec_1=cvec2(1:nsamp)>nsamp;
    out_vec_2=cvec(1:nsamp)>nsamp;

    X2=NaN*ones(nptsd,2);
    X2(1:nsamp,:)=contour_1;
    X2=X2(cvec,:);
    X2b=NaN*ones(nptsd,2);
    X2b(1:nsamp,:)=contour_1;
    X2b=X2b(cvec,:);
    Y2=NaN*ones(nptsd,2);
    Y2(1:nsamp,:)=contour_2;

    ind_good=find(~isnan(X2b(1:nsamp,1)));
    n_good=length(ind_good);
    X3b=X2b(ind_good,:);
    Y3=Y2(ind_good,:);

    figure(2)
    plot(X2(:,1),X2(:,2),'g^',Y2(:,1),Y2(:,2),'ro')
    hold on
    h=plot([X2(:,1) Y2(:,1)]',[X2(:,2) Y2(:,2)]','k-');

    %	 set(h,'linewidth',1)
    quiver(contour_1(:,1),contour_1(:,2),cos(shape_1_theta),sin(shape_1_theta),0.5,'g')
    quiver(contour_2(:,1),contour_2(:,2),cos(shape_2_theta),sin(shape_2_theta),0.5,'r')

    hold off
    axis('ij')
    axis([1 shape_dim_2 1 shape_dim_1])
    drawnow	

    % show the correspondences between the untransformed images
    figure(3)
    plot(contour_1(:,1),contour_1(:,2),'g^',contour_2(:,1),contour_2(:,2),'ro')
    ind=cvec(ind_good);
    hold on
    plot([X2b(:,1) Y2(:,1)]',[X2b(:,2) Y2(:,2)]','k-')
    hold off
    axis('ij')
    title([int2str(n_good) ' correspondences (unwarped X)'])
    axis([1 shape_dim_2 1 shape_dim_1])
    drawnow	

    [cx,cy,E]=bookstein(X3b,Y3,beta_k);

    % calculate affine cost
    A=[cx(n_good+2:n_good+3,:) cy(n_good+2:n_good+3,:)];
    warping=svd(A);
    aff_cost=log(warping(1)/warping(2));

    % calculate shape context cost
    [a1,b1]=min(costmat,[],1);
    [a2,b2]=min(costmat,[],2);
    sc_cost=max(mean(a1),mean(a2));

    %Call computeAlignmentTransform script
    computeAlignmentTransform

    % update contour_1 for the next iteration
    contour_1=Z;

    if current_iteration==n_iter
        warping=0;
    else
        current_iteration=current_iteration+1;
    end
end