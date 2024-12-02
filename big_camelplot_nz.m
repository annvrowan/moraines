%% This block creates camel diagrams for all moraines and orders them by age and latitude.
% Modified by KP November 2024

clear;

% Load data
data = readtable('../geochron.xlsx','Sheet', 1);
save('10be.mat', 'data');
load 10be.mat;

%Assign variables
site_name = table2cell(data(:,8));
site_lat = cell2mat(table2cell(data(:,2)));
site_lon = cell2mat(table2cell(data(:,3)));
age = cell2mat(table2cell(data(:,5)));
dtint = cell2mat(table2cell(data(:,6))); %internal uncertainty
dtext = cell2mat(table2cell(data(:,7))); %external uncertainty

%% Chronologically-ordered plot



unique_sites = unique(site_name); % Get unique site names
plotht =1./(length(unique_sites)+4); 

% Initialize a cell array to store camelplot data
cps = struct('x', {}, 'y', {}, 'name', {});

% Loop to calculate and store camelplot for each site
for s = 1:length(unique_sites)
    thisname = unique_sites{s};
    indices = find(strcmp(site_name, thisname)); % Find indices for this site name

    % Aggregate ages and dtint values for this site name
    thist = age(indices);
    thisdt = dtint(indices);

    % Camelplot for each site
    thiscp = camelplot(thist, thisdt);

    okx = find(thiscp.x > 0);
    
    % Store in struct
    cps(s).x = thiscp.x(okx);
    cps(s).y = thiscp.y(okx);
    cps(s).name = thisname;
end

% Sort by age, sorting cps.x values
[sortedx, sortIdx]=sort(arrayfun(@(c) c.x(2), cps));
cps = cps(sortIdx);


% Create figure

figure('pos',[440    42   574   760]);

% The following parameter controls how tall the camel plots are in relation
% to the spacing. Adjust to make it look good.

camelHtScale = 6;

axes()

lastlat = -90;


% Plot each camelplot chronologically
for s = 1:length(unique_sites)
    thiscp = cps(s);
    thisbasey = (s + 2) * plotht;
    thisx = [1 thiscp.x 4e5];
    thisy = [thisbasey (thiscp.y * (camelHtScale * plotht / max(thiscp.y)) + thisbasey) thisbasey];
   
   % Plot entire camel
    plot(thisx,thisy,'color',[0.4 0.4 0.4]); hold on;
end

% Define things having to do with ACR and YD
% ACRmin = 13000; ACRmax = 14700;
% YDmin = 11700; YDmax = 12900;

    % This commented-out section attempts to color in sections of each
    % camel plot that belongs to the YD or ACR. Also see some commented-out
    % lines above that define YDmax, etc.
    %
    % YDi = find(thisx >= YDmin & thisx <= YDmax);
    % ACRi = find(thisx >= ACRmin & thisx <= ACRmax);
    % sum_all = sum(thisy);
    % sum_YD = sum(thisy(YDi));
    % sum_ACR = sum(thisy(ACRi));
    % pYD(a) = sum_YD./sum_all;
    % pACR(a) = sum_ACR./sum_all;
    % YDx = [thisx(YDi) fliplr(thisx(YDi)) thisx(YDi(1))];
    % YDy = [thisy(YDi) zeros(size(YDi))+thisbasey thisy(YDi(1))];
    % patch(YDx,YDy,[0.8 0.8 1],'edgecolor',[0.9 0.9 1]);
    % ACRx = [thisx(ACRi) fliplr(thisx(ACRi)) thisx(ACRi(1))];
    % ACRy = [thisy(ACRi) zeros(size(ACRi))+thisbasey thisy(ACRi(1))];
    % patch(ACRx,ACRy,[0.8 1 0.8],'edgecolor',[0.9 1 0.9]);


set(gcf,'color','w')
set(gca,'box','off')
set(gca,'ycolor','w')
set(gca,'xtick',[0:10000:50000])
%set(gca,'xticklabel',{'0','2','4','6','8','10','12','14','16','18','20','22','24'})
xlabel('Exposure age (yrs)');
title('Summary camelplots for moraines of the Southern Alps, New Zealand')
tx = get(gca,'xaxis');
tx.Exponent=0;
set(tx,'limits',[0 50000])
set(gca,'ylim',[0 1])
drawnow;

% Identify the YD
%plot([12900 12900],[0.02 0.98],'b');
%plot([11700 11700],[0.02 0.98],'b');
%text(mean([11700 12900]),0.02,'YD','fontsize',8,'fontname','helvetica','horizontalalignment','center','color','b')

% Identify the ACR
%plot([14700 14700],[0.02 0.98],'g');
%plot([13000 13000],[0.02 0.98],'g');
%text(mean([14700 13000]),0.02,'ACR','fontsize',8,'fontname','helvetica','horizontalalignment','center','color','g')

%set(gca,'xlim',[0 25000])

%% Try it in log
set(gca,'xscale','log');
set(gca,'xtickmode','auto','xticklabelmode','auto')
set(gca,'xlim',[100 100000])
grid on;

%% This block aggregates data from latitude bins to plot camel diagrams in
% a correct latitude relationship.


% Sort by latitude
[sorted, sortindex] = sort(site_lat,'descend');

% Define latitude bins
lats = -46:0.25:-40;

figure('pos',[440    42   574   760]);
plotht = 1;
camelHeightScale = 1; % sets height of plots rel to spacing
axes()
set(gca,'xlim',[-3000 40000],'ylim',[-46 -40]);

for a = 2:length(lats)
    use = find((site_lat >= lats(a-1)) & (site_lat < lats(a)));
    this_t = [];
    this_dt = [];
    for b = 1:length(use)
        if ~isempty(age(use(b))) & isempty(find(age(use(b)) == 0))
            this_t = [this_t age(use(b))];
            this_dt = [this_dt dtint(use(b))];
        end
    end
    if ~isempty(this_t)
        thiscp = camelplot(this_t,this_dt);
        okx = find(thiscp.x > 0);
        thisx = [1 thiscp.x(okx) 1e6];
        thisy = [lats(a) (thiscp.y(okx).*(camelHeightScale.*plotht./max(thiscp.y)) + lats(a)) lats(a)];
        cc = [0.2 0.2 0.2];
        tag = 'a';
        plot(thisx,thisy,'color',cc,'tag',tag); hold on; drawnow;
    else
        thisx = [1 1e6];
        thisy = [lats(a) lats(a)];
        thisz = [-1 -1];
        cc = [0.8 0.8 0.8];
        tag = 'b';
        plot3(thisx,thisy,thisz,'color',cc,'tag',tag); hold on; drawnow;
    end

end

view(0,90);

% This makes some y-axis labels that are out of the way on the left
plats = [-46:1:-40];
for a = 1:length(plats)
    text(-400,plats(a),[int2str(plats(a)) '  -'],'fontsize',12,'fontname','helvetica','horizontalalignment','right');
end

tt1 = text(-1800,0,'Latitude','fontsize',10,'fontname','helvetica','horizontalalignment','center','rotation',90)

set(gcf,'color','w')
set(gca,'box','off')
set(gca,'ycolor','w')
set(gca,'gridcolor',[0.5 0.2 0.2])
set(gca,'ygrid','off','xgrid','on')
set(gca,'xtick',[0:5000:80000])
%set(gca,'xticklabel',{'0','2','4','6','8','10','12','14','16','18','20','22','24'})
set(gca,'ytick',[-46:0.5:-40]);
set(gca,'yticklabel',{'-60', '-50', '-40', '-30', '-20', '-10', '0', '10', '20', '30', '40', '50', '60', '70'});
xlabel('Exposure age (ka)');
ylabel('Latitude (°S)');
title('Moraines of the Southern Alps')
tx = get(gca,'xaxis');
set(tx,'limits',[-1 70000])
set(gca,'ylim',[-46 -39]);




