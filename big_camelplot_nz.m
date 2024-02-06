%% This block creates camel diagrams for all moraines and orders them by latitude.
% Note: because the moraines aren't evenly spaced, the y-axis isn't
% anything like linear with latitude. Thus, plot some latitude markers
% occasionally to indicate where we are.
%
% Note: this is now kind of way too dense. Too much data.

clear;

% Reload data
load sample_data_nz.mat;

% Sort by latitude

ok_is = find(OK == 1);
ok_lats = site_lat(ok_is);
[sorted,sortindex] = sort(ok_lats);

% Create figure
figure('pos',[440    42   574   760]);


plotht =1./(length(ok_lats)+4);

% The following parameter controls how tall the camel plots are in relation
% to the spacing. Adjust to make it look good.

camelHtScale = 3;

axes()

lastlat = -90;

% Define things having to do with ACR and YD
% ACRmin = 13000; ACRmax = 14700;
% YDmin = 11700; YDmax = 12900;

for a = 1:length(sortindex)
    thisi = ok_is(sortindex(a));
    thisname = site_names{a};
    thist = all_ages(thisi).t;
    thisdt = all_ages(thisi).dtint;
    thiscp = camelplot_all(thist,thisdt);
    thisbasey = (a+2).*plotht;
    okx = find(thiscp.x > 0);
    thisx = [1 thiscp.x(okx) 5e5];
    thisy = [thisbasey (thiscp.y(okx).*(camelHtScale.*plotht./max(thiscp.y)) + thisbasey) thisbasey];


    % Plot entire camel
    plot(thisx,thisy,'color',[0.4 0.4 0.4]); hold on;

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

    % This section plots the latitude periodically in the left margin.
    % Detect a latitude transition
    thislat = site_lat(thisi);
    if (a > 1) && (ceil(lastlat./1) == floor(thislat./1))
        % Crossed 5-degree bound
        plat = 1.*ceil(lastlat./1);
        if plat == 0
            thistext = '0';
        elseif plat > 0
            thistext = [sprintf('%0.0f',plat) ' N'];
        else
            thistext = [sprintf('%0.0f',plat) ' S'];
        end
        plot([-900 -500],(thisbasey + 0.5*plotht).*[1 1],'k');
        text(-1000,(thisbasey + 0.5*plotht),thistext,'fontsize',12,'fontname','helvetica','horizontalalignment','right')
    end
    drawnow;
    lastlat = thislat;
end


set(gcf,'color','w')
set(gca,'box','off')
set(gca,'ycolor','w')
set(gca,'xtick',[0:2000:40000])
%set(gca,'xticklabel',{'0','2','4','6','8','10','12','14','16','18','20','22','24'})
xlabel('Exposure age (ka)');
title('LGM and Holocene moraines of the Southern Alps, New Zealand, from 22–40 degrees S')
tx = get(gca,'xaxis');
set(tx,'limits',[0 40000])
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

% Define latitude bins
lats = -40:0.5:-20;

figure('pos',[440    42   574   760]);
plotht = 1;
camelHeightScale = 2; % sets height of plots rel to spacing
axes()
set(gca,'xlim',[-3000 40000],'ylim',[-40 -22]);

for a = 2:length(lats)
    use = find((site_lat >= lats(a-1)) & (site_lat < lats(a)));
    this_t = [];
    this_dt = [];
    for b = 1:length(use)
        if ~isempty(all_ages(use(b)).t) & isempty(find(all_ages(use(b)).t == 0))
            this_t = [this_t all_ages(use(b)).t'];
            this_dt = [this_dt all_ages(use(b)).dtint'];
        end
    end
    if ~isempty(this_t)
        thiscp = camelplot_all(this_t,this_dt);
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
plats = [-40:10:-20];
for a = 1:length(plats)
    text(-400,plats(a),[int2str(plats(a)) '  -'],'fontsize',12,'fontname','helvetica','horizontalalignment','right');
end

tt1 = text(-1800,0,'Latitude','fontsize',10,'fontname','helvetica','horizontalalignment','center','rotation',90)

set(gcf,'color','w')
set(gca,'box','off')
set(gca,'ycolor','w')
set(gca,'gridcolor',[0.5 0.2 0.2])
set(gca,'ygrid','off','xgrid','on')
set(gca,'xtick',[0:2000:40000])
%set(gca,'xticklabel',{'0','2','4','6','8','10','12','14','16','18','20','22','24'})
set(gca,'ytick',[-40:10:-20]);
set(gca,'yticklabel',{'-60', '-50', '-40', '-30', '-20', '-10', '0', '10', '20', '30', '40', '50', '60', '70'});
xlabel('Exposure age (ka)');
title('LGM and Holocene moraines of the American cordillera')
tx = get(gca,'xaxis');
set(tx,'limits',[-1 40000])
set(gca,'ylim',[-40 -20]);




