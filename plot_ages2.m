%A script to plot the latitude, elevation and age clusters of Holocene
%moraines in New Zealand

%Based on Himalaya LIA analyses

%Created 21/12/15 by AVR
%Last modified: 16/08/21 by Ann

clear all
%% I/O

%Set max age to include in ka
max_age = 18;

data = load('2021_nonTCN_lat_long_elev_rel_n_conf_age_err.txt');
lat = data(:,1);
long = data(:,2);
elev = data(:,3);
rel = data(:,4);
num = data(:,5);
conf = data(:,6);
age = data(:,7);
err = data(:,8);

age = age/1000;
err = err/1000;
n_landforms = size(age); n_landforms = 1:n_landforms(1,1);


%% Compute pdf
arg_1 = age(:);
%Prepare figure
clf
figure(1)
subplot(1,2,1); histogram(age,20); box on; xlabel('Age of landform (ka)'); ylabel('Count')

subplot(1,2,2); hold on;
[CdfF,CdfX] = ecdf(arg_1,'Function','cdf');  % compute empirical cdf
BinInfo.rule = 5;
BinInfo.width = 1;
BinInfo.placementRule = 1;
[~,BinEdge] = internal.stats.histbins(arg_1,[],[],BinInfo,CdfF,CdfX);
[BinHeight,BinCenter] = ecdfhist(CdfF,CdfX,'edges',BinEdge);
hLine = bar(BinCenter,BinHeight,'hist');
set(hLine,'FaceColor','none','EdgeColor',[0.333333 0 0.666667],...
    'LineStyle','-', 'LineWidth',1);
xlabel('Age of landform (ka)');
ylabel('Density')
%axes([0 2000 0 15000])

% Create grid where function will be computed
XLim = get(gca,'XLim');
XLim = XLim + [-1 1] * 0.01 * diff(XLim);
XGrid = linspace(XLim(1),XLim(2),100);
%Data = arg_1(Excluded);
pd1 = fitdist(arg_1,'kernel','kernel','normal','support',[0 max_age],'width',1);
YPlot = pdf(pd1,XGrid);
hLine = plot(XGrid,YPlot,'Color',[1 0 0],...
    'LineStyle','-', 'LineWidth',1,...
    'Marker','none', 'MarkerSize',6);
box on;

%% Plot probabilities by elevation, latitude and longitude
% Prepare figure
figure(2)
subplot(2,2,1);
hLine = probplot('normal',age,[],[],'noref');
set(hLine,'Color','k','Marker','.', 'MarkerSize',20);
xlabel('Age of landform (ka)');
ylabel('Probability')
box on; hold off;

elev(elev==0)=NaN;
lat(lat==0)=NaN;
long(long==0)=NaN;

subplot(2,2,2); errorbar(elev,age,err,-err,'ko'); xlabel('Elevation (m a.s.l.)'); ylabel('Age of landform (ka)')
subplot(2,2,3); errorbar(lat,age,err,-err,'ko'); xlabel('Latitude (dd)'); ylabel('Age of landform (ka)')
subplot(2,2,4); errorbar(long,age,err,-err,'ko'); xlabel('Longitude (dd)'); ylabel('Age of landform (ka)')

%% Plot ages by lat/long weighted by inverse of error
coast = shaperead('ne_10m_coastline/ne_10m_coastline.shp','UseGeoCoords',true);



figure(3)
hold on
msize = (age./err)*20; scatter(long,lat,msize,age,'filled')
geoshow(coast)
ylabel('Latitude (dd)'); xlabel('Longitude (dd)')
title('Landform age (ka) where points are scaled inversely with error (n = 91)')
axis equal
axis([166 175 -48 -40]);

colormap jet; colorbar; box on

%% Calculate weighted mean 
%(wm = sum of value * weight, divided by sum of weights)
weights = 1./err;
n_landforms = size(age); n_landforms = n_landforms(1,1);
weighted_mean = (sum(age .* err))/(sum(err))
sumsqerr = sqrt((sum(err.^2)/n_landforms))




