% This gets calibration data from the ICE-D:CALIBRATION website, obtains
% calibrated production rate parameters with it, and uses those calibrated
% production rate parameters to compute exposure ages at an unknown-age
% site. 
% Source retrieved 26/11/24 by KP from: https://wiki.ice-d.org/pluginto:calculators

clear all;

% Get some calibration data from the calibration website

cal_page_html = webread('http://calibration.ice-d.org/cds/1');

% Note: this input data must include data for only one nuclide

% Scrape the formatted text block out of the HTML
startindex = strfind(cal_page_html,'<!-- begin v3 --><pre>') + length('<!-- begin v3 --><pre>');
endindex = strfind(cal_page_html,'</pre><!-- end v3 -->') - 1;
cal_input_text = cal_page_html(startindex:endindex);

%% Send that to the online calculator and get calibration results

url = "http://hess.ess.washington.edu/cgi-bin/matweb";
cal_xml_result = webread(url,'mlmfile','cal_input_v3','reportType','XML','plotFlag','no','text_block',cal_input_text);

% Extract calibration information from XML. This is a stupid regexp
% matching scheme. In MATLAB R2021 you can use the proper XML parser. 

% First, get the name of the nuclide -- eventually you will have to send this to the
% calibration code, because you can only do a calibration for one nuclide
% at a time. 

temp = regexp(cal_xml_result,['<nuclide>(.*?)</nuclide>'],'tokens');
nuclide_string = temp{1}{1};

% Get calibrated production rate parameters
% Obviously, the below could be shortened by looping over scaling methods
temp = regexp(cal_xml_result,['<summary_value_St>(.*?)</summary_value_St>'],'tokens');
value_St_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_uncert_St>(.*?)</summary_uncert_St>'],'tokens');
uncert_St_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_value_Lm>(.*?)</summary_value_Lm>'],'tokens');
value_Lm_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_uncert_Lm>(.*?)</summary_uncert_Lm>'],'tokens');
uncert_Lm_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_value_LSDn>(.*?)</summary_value_LSDn>'],'tokens');
value_LSDn_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_uncert_LSDn>(.*?)</summary_uncert_LSDn>'],'tokens');
uncert_LSDn_string = temp{1}{1};

%% Now we have the production rate parameters obtained from the calibration
% data. 

% Get some data from ICE-D:ALPINE to calculate the exposure age of

unknowns_page_html = webread('http://alpine.ice-d.org/site/BST');

% Get the formatted text out of the HTML 

startindex = strfind(unknowns_page_html,'<!-- begin v3 --><pre>') + length('<!-- begin v3 --><pre>');
endindex = strfind(unknowns_page_html,'</pre><!-- end v3 -->') - 1;
unknowns_input_text = unknowns_page_html(startindex:endindex);


%% Send sample info to exposure age calculator with additional options to
% force non-default Be-10 production rate

url = "https://hess.ess.washington.edu/cgi-bin/matweb";

unknowns_xml_result_calibrated = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no',...
    'text_block',unknowns_input_text,...
    'trace_string','nothing here but this is required',...
    'calib_name','nothing here either but this is required too',...
    'nuclide_name',nuclide_string,...
    'P_St',value_St_string,'delP_St',uncert_St_string,...
    'P_Lm',value_Lm_string,'delP_Lm',uncert_Lm_string,...
    'P_LSDn',value_LSDn_string,'delP_LSDn',uncert_LSDn_string);

%% Here is what it would look like if we omit the additional calibration 
% parameters. In this case we get the results using the normal default
% production rate calibration. 

unknowns_xml_result_default = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no',...
    'text_block',unknowns_input_text);

% We leave it as an exercise for the student to extract the exposure ages
% from unknowns_xml_result_calibrated and unknowns_xml_result_default, and
% verify that they are different. 