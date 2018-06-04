function forestDB()
%%
clear;
clc;


NUM_OF_GROUPS = 140;
R = 5;
centers = csvread('centers.txt');

fprintf('File Path Ready!\n');
groups = [];


for group_i = 1:NUM_OF_GROUPS
   groups(group_i).trainData=[];
   groups(group_i).centerHor = centers(group_i,1);
   groups(group_i).centerVert = centers(group_i,2);
   groups(group_i).index = 0;
   groups(group_i).trainData.headpose = [];
   groups(group_i).trainData.data = [];
   groups(group_i).trainData.label = [];
   groups(group_i).name = strcat( 'group', num2str(group_i) ); 
   groups(group_i).RnearestCenters = zeros(R,2);
   
end



%%%training
%trainData=[];
%trainData.data = zeros(60,36,1, 15*1125*2);%zeros(60,36,1, total_num*2);
%trainData.label = zeros(2, 15*1125*2);%zeros(2, total_num*2);
%trainData.headpose = zeros(2, 15*1125*2);%zeros(2, total_num*2);
%trainData.confidence = zeros(1, 15*1125*2);%zeros(1, total_num*2);
%trainindex = 0;

%test
testData=[];
testData.data = zeros(60,36,1, 15*375*2);%zeros(60,36,1, total_num*2);
testData.label = zeros(2, 15*375*2);%zeros(2, total_num*2);
testData.headpose = zeros(2, 15*375*2);%zeros(2, total_num*2);
%testData.confidence = zeros(1, 15*375*2);%zeros(1, total_num*2);
testindex = 0;

%temp
tempData=[];
tempData.data = zeros(60,36,1, 1*2);%zeros(60,36,1, total_num*2);
tempData.label = zeros(2, 1*2);%zeros(2, total_num*2);
tempData.headpose = zeros(2, 1*2);%zeros(2, total_num*2);
%tempData.confidence = zeros(1, 1*2);%zeros(1, total_num*2);


minPoseHoriz = 30;
minPoseVert = 30;
maxPoseHoriz = -30;
maxPoseVert = -30;

one = 0;
two = 0;
three = 0;
four = 0;
%Pij lists all p00, p01, p02,...
dirData = dir(pwd);
dirIndex = [dirData.isdir];
Pij = dirData(dirIndex);
%for each Pij...
 for num_Pij=3:length(Pij)
   filepath = strcat(Pij(num_Pij).name, '/'); %'p00/';%'MPIIGaze/';
 
  %%% LIST ALL FILES %%%
  dirData = dir(filepath);%path = dir(filepath);
  dirIndex = [dirData.isdir];
  files = {dirData(~dirIndex).name}';

  %%%% STEPS %%%%
  step_size = get_step_size( filepath);
  curr_step = 1;

  %%% TRAINING vs TEST RATIO(75%) %%%
  ratio = 3; % 75% are for training, 25% for test
  curr_ratio = 0;

  for num_f=1:length(files) 
   
    readname = [filepath, files{num_f}];
    temp = load(readname);   
    num_data = length(temp.filenames(:,1));   
    for num_i=1:num_data
      if curr_step == step_size 
	curr_step = 1;
      	

	% for left
        img = temp.data.left.image(num_i, :,:);
        img = reshape(img, 36,60);
       	tempData.data(:, :, 1, 1) = img'; % filp the image
        
        Lable_left = temp.data.left.gaze(num_i, :)';
        theta = asin((-1)*Lable_left(2));
        phi = atan2((-1)*Lable_left(1), (-1)*Lable_left(3));
        tempData.label(:,1) = [theta; phi];
 
        headpose = temp.data.left.pose(num_i, :);
        M = rodrigues(headpose);
        Zv = M(:,3);
        theta = asin(Zv(2));
        phi = atan2(Zv(1), Zv(3));


        tempData.headpose(:,1) = [theta;phi];         
         
        % for right
        img = temp.data.right.image(num_i, :,:);
        img = reshape(img, 36,60);
        tempData.data(:, :, 1, 2) = double(flip(img, 2))'; % filp the image
         
        Lable_right = temp.data.right.gaze(num_i,:)';
        theta = asin((-1)*Lable_right(2));
        phi = atan2((-1)*Lable_right(1), (-1)*Lable_right(3));
        tempData.label(:,2) = [theta; (-1)*phi];% flip the direction

        headpose = temp.data.right.pose(num_i, :); 

        M = rodrigues(headpose);
        Zv = M(:,3);
        theta = asin(Zv(2));
       	phi = atan2(Zv(1), Zv(3));
        tempData.headpose(:,2) = [theta; (-1)*phi]; % flip the direction
	
	if  curr_ratio == 3 %0
		curr_ratio = 0;
		%%%%%%%%%%%%%%%
		% TEST DATA
		%%%%%%%%%%%%%%%
		%copy left
		testindex = testindex+1;
		testData.data(:, :, 1, testindex) = tempData.data(:, :, 1,1);
		testData.label(:,testindex) = tempData.label(:,1);
		testData.headpose(:,testindex) = tempData.headpose(:,1);

		%copy right
		testindex = testindex+1;
		testData.data(:, :, 1, testindex) = tempData.data(:, :, 1, 2);
		testData.label(:,testindex) = tempData.label(:,2);
		testData.headpose(:,testindex) = tempData.headpose(:,2);
	else %0,1,2
		curr_ratio = curr_ratio + 1;
		%%%%%%%%%%%%%%%
                % TRAINING DATA
                %%%%%%%%%%%%%%%

		%copy left
		groupID = find_nearest_group(tempData.headpose(:,1), groups);

		groups(groupID).index = groups(groupID).index + 1;
		groups(groupID).trainData.data(:, :,1,groups(groupID).index) = tempData.data(:, :, 1,1);
		groups(groupID).trainData.label(:,groups(groupID).index) = tempData.label(:,1);
		groups(groupID).trainData.headpose(:,groups(groupID).index) = tempData.headpose(:,1);
                %trainindex = trainindex+1;
                %trainData.data(:, :, 1, trainindex) = tempData.data(:, :, 1,1);
                %trainData.label(:,trainindex) = tempData.label(:,1);
                %trainData.headpose(:,trainindex) = tempData.headpose(:,1);
	

                %copy right
		groupID = find_nearest_group(tempData.headpose(:,2), groups);

		groups(groupID).index = groups(groupID).index + 1;
		groups(groupID).trainData.data(:, :,1,groups(groupID).index) = tempData.data(:, :, 1,2);
		groups(groupID).trainData.label(:,groups(groupID).index) = tempData.label(:,2);
		groups(groupID).trainData.headpose(:,groups(groupID).index) = tempData.headpose(:,2);
                %trainindex = trainindex+1;
                %trainData.data(:, :, 1, trainindex) = tempData.data(:, :, 1, 2);
                %trainData.label(:,trainindex) =  tempData.label(:,2);
                %trainData.headpose(:,trainindex) = tempData.headpose(:,2);

	end % training Or Test????

     else % not in the samples
	curr_step = curr_step + 1;
     end	
    end %data per file

    fprintf('%d / %d !\n', num_f, length(files)); 
  end % for each file
end  % for each pij
fprintf('Saving\n');

%testData.data = testData.data/255; %normalize
%testData.data = single(testData.data); % must be single data, because caffe want float type
%testData.label = single(testData.label);
%testData.headpose = single(testData.headpose);


%grid('ON');
%scatter( trainData.headpose(1,:), trainData.headpose(2,:), '*', 'b' );

savename = 'small_MPII_traindata.h5';

%start creating data file for training(HDF5)
fid = H5F.create('myfile.h5');
type_id = H5T.copy('H5T_NATIVE_DOUBLE');
dcpl = 'H5P_DEFAULT';
plist = 'H5P_DEFAULT';


for i = 1:140
	
	groups(i).trainData.data = groups(i).trainData.data/255; %normalize
	groups(i).trainData.data = single(groups(i).trainData.data); % must be single data, because caffe want
	groups(i).trainData.label = single(groups(i).trainData.label);
	
	groups(i).trainData.headpose = single(groups(i).trainData.headpose);
	grp = H5G.create(fid, strcat('g', num2str(i)) ,plist,plist,plist);
	
%%%%%% Dataset 1: numx1x36x60 image data %%%%	
	dims = [groups(i).index 1 36 60];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(4,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i), '/data') ,type_id,space_id,dcpl);		
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,groups(i).trainData.data);
	H5D.close(dset);
	H5S.close(space_id);


%%%%%% Dataset 2: numx4 pose and gaze data %%%%	
	dims = [groups(i).index 4];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i),'/label'), type_id,space_id,dcpl);	
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,[groups(i).trainData.label; groups(i).trainData.headpose]);
	H5D.close(dset);
	H5S.close(space_id);


%%%%%% Dataset 3: headpose-center of each group  %%%%	
	dims = [1 2];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i),'/center'), type_id,space_id,dcpl);	
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,[groups(i).centerHor groups(i).centerVert] );
	H5D.close(dset);
	H5S.close(space_id);

%%%%%% Dataset 4: List of R-nearest groups %%%%

	listOfGroupIds = find_R_nearest_groups(groups(i).centerHor, groups(i).centerVert, groups, R, [] );
	dims = [1 R];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i),'/',num2str(R),'_nearestIDs'), type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist, listOfGroupIds );
	H5D.close(dset);
	H5S.close(space_id);	
	
%	hdf5write(savename,strcat( groups(i).name,'/data'), groups(i).trainData.data, strcat(groups(i).name,'/label'), [groups(i).trainData.label; groups(i).trainData.headpose]);
 
end
H5F.close(fid);

%hold on;
%scatter(centers(:,1), centers(:,2), '*', 'r');
%store2hdf5(savename, Data.data, Data.label, 1, 1); % the store2hdf5 function comes from https://github.com/BVLC/caffe/pull/1746
%hdf5write(savename,'/data', trainData.data, '/label',[trainData.label; trainData.headpose]); 
fprintf('done\n');


savename = 'small_MPII_testdata.h5';
%store2hdf5(savename, Data.data, Data.label, 1, 1); % the store2hdf5 function co
%% You can also use the matlab function for hdf5 saving:
hdf5write(savename,'/data', testData.data, '/label',[testData.label; testData.headpose]); 
fprintf('done\n\n');



end




function nearestGroup = find_nearest_group(headpose, groups)
  minDist = 100;
  nearestGroup = -1;   

  for i =1:140
     distHor = abs(groups(i).centerHor - headpose(1));
     distVert = abs(groups(i).centerVert - headpose(2));
     if  distHor < 0.2 && distVert < 0.2 
	dist =  sqrt( distHor^2 + distVert^2 );
        if  dist < minDist
	   minDist = dist;
	   nearestGroup = i;
	end
     end
  end
  %minDist


end


function listOfGroupIds = find_R_nearest_groups(centerHor, centerVert, groups, timesLeft, listOfGroupIds)
  minDist = 100;
  nearestGroup = -1;   

  for i =1:140
     if isnt_in_the_list(i, listOfGroupIds) == 1    
     	distHor = abs(groups(i).centerHor - centerHor);
     	distVert = abs(groups(i).centerVert - centerVert);
     	if  distHor < 0.2 && distVert < 0.2 
	   dist =  sqrt( distHor^2 + distVert^2 );
           if  dist < minDist
	      minDist = dist;
	      nearestGroup = i;
	   end
        
	end
     
      end

   end
   
  listOfGroupIds( length(listOfGroupIds)+1 ) = nearestGroup;
  timesLeft = timesLeft - 1;

  if timesLeft > 0
        listOfGroupIds = find_R_nearest_groups(centerHor, centerVert, groups, timesLeft, listOfGroupIds);
  end

 


end



function out = isnt_in_the_list(currGroup, listOfGroupIds)
   
   out = 1;
   for i = 1:length(listOfGroupIds)
      if currGroup == listOfGroupIds(i)
         out =  0;
        
      end
   end

end




