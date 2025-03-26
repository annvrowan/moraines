%A script to plot the latitude, elevation and age clusters of Holocene
%moraines in New Zealand

%Based on Himalaya LIA analyses

%Created 21/12/15 by AVR
%Last modified: 16/08/21 by Ann
%Last modified: 26/03/2025 by Karlijn

clear all
%% I/O

%Set max age to include in ka
max_age =80;

%%
data_TCN = readtable('data/geochronology_summary_MATLAB.xlsx', 'Sheet', 'TCN');
data_lumin = readtable('data/geochronology_summary_MATLAB.xlsx', 'Sheet', 'lumin');
data_14C = readtable('data/geochronology_summary_MATLAB.xlsx', 'Sheet', '14C');

%Add dating method to each table 
data_TCN.method = repmat({'TCN'}, height(data_TCN), 1);
data_lumin.method = repmat({'lumin'}, height(data_lumin), 1);
data_14C.method = repmat({'14C'}, height(data_14C), 1);

%Merge data
data = [data_TCN; data_lumin; data_14C];

%%
lat = data{:, 1};
long = data{:, 2};
elev = data{:, 3};
rel = data{:, 4};
conf = data{:, 5};
age = data{:, 6};
err = data{:, 7};
method=data{:, 8};

age = age/1000;
err = err/1000;
n_samples = size(age); n_samples = 1:n_samples(1,1);

%%
figure(1)

% Define the edges of the bins
edges = 0:5:100;

% Initialize counts for each method
counts1 = histcounts(age(method == "TCN"), edges);
counts2 = histcounts(age(method == "lumin"), edges);
counts3 = histcounts(age(method == "14C"), edges);

% Combine counts into a matrix
counts = [counts1; counts2; counts3]';

% Create a stacked bar chart
bar(edges(1:end-1) + diff(edges)/2, counts, 'stacked', 'BarWidth', 1);

% Add labels and title
xlabel('Age (ka)');
ylabel('Count');
title('Stacked Histogram of Age by Method');
legend('TCN', 'Lumin', '14C');


%% Compute pdf
%arg_1 = age(:);
arg_1 = age(age <= max_age);

%Prepare figure
clf
figure(2)
subplot(1,2,1); histogram(arg_1,20); box on; xlabel('Age of sample (ka)'); ylabel('Count')

subplot(1,2,2); hold on;
[CdfF,CdfX] = ecdf(arg_1,'Function','cdf');  % compute empirical cdf
BinInfo.rule = 5;
BinInfo.width = 5;
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
XGrid = linspace(XLim(1),XLim(2),80);
%Data = arg_1(Excluded);
pd1 = fitdist(arg_1,'kernel','kernel','normal','support',[0 max_age],'width',1);
%pd1 = fitdist(arg_1,'kernel','kernel','normal','support','unbounded','width',1);
YPlot = pdf(pd1,XGrid);
hLine = plot(XGrid,YPlot,'Color',[1 0 0],...
    'LineStyle','-', 'LineWidth',1,...
    'Marker','none', 'MarkerSize',6);
box on;

%% Plot probabilities by elevation, latitude and longitude
% Prepare figure
figure(3)
subplot(2,2,1);
hLine = probplot('normal',age,[],[],'noref');
set(hLine,'Color','k','Marker','.', 'MarkerSize',20);
xlabel('Age of sample (ka)');
ylabel('Probability')
box on; hold off;

elev(elev==0)=NaN;
lat(lat==0)=NaN;
long(long==0)=NaN;

subplot(2,2,2); errorbar(elev,age,err,-err,'ko'); xlabel('Elevation (m a.s.l.)'); ylabel('Age of sample (ka)')
subplot(2,2,3); errorbar(lat,age,err,-err,'ko'); xlabel('Latitude (dd)'); ylabel('Age of sample (ka)')
subplot(2,2,4); errorbar(long,age,err,-err,'ko'); xlabel('Longitude (dd)'); ylabel('Age of sample (ka)')

%% Plot ages by lat/long weighted by inverse of error
coast = shaperead('ne_10m_coastline/ne_10m_coastline.shp','UseGeoCoords',true);

figure(4)
hold on
msize = (age./err)*5; 
scatter(long,lat,msize,age,'filled')
geoshow(coast,'Color', 'k')
ylabel('Latitude (dd)'); xlabel('Longitude (dd)')
title('Sample age (ka) where points are scaled inversely with error (n = 1441)')
axis equal
axis([166 174.5 -48 -40]);

colormap jet; colorbar; box on
caxis([0 80]); 

%% Calculate weighted mean 
%(wm = sum of value * weight, divided by sum of weights)
weights = 1./err;
n_samples = size(age); n_samples = n_samples(1,1);
weighted_mean = (sum(age .* err))/(sum(err))
sumsqerr = sqrt((sum(err.^2)/n_samples))




