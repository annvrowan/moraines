%function [names,LSDn_ages,LSDn_ints,LSDn_exts,sum_val,sum_int,sum_ext] = cosmo_calculator(sample_data)
function [ages_global,ages_local] = cosmo_calculator(sample_data, parameters)


%A script to send sample data to the online cosmo calculator and collect the
%results. Sample_data is the sample info returned from ICE-D by the script
%iced_query.m that has been reformatted to tab spaced for cosmo calculator.

%Example copied from cosmo calc website
%text = ['PH-1',sprintf('\t'),num2str(41.3567),sprintf('\t'),num2str(-70.7348),sprintf('\t'),num2str(91),sprintf('\t'),'std',sprintf('\t'),num2str(4.5),sprintf('\t'),num2str(2.65),sprintf('\t'),num2str(1),sprintf('\t'),num2str(0.00008),sprintf('\t'),num2str(1999),';', sprintf('\n'),'PH-1',sprintf('\t'),'Be-10',sprintf('\t'),'quartz',sprintf('\t'),num2str(123453),sprintf('\t'),num2str(3717),sprintf('\t'),'KNSTD;',sprintf('\n'),'PH-1',sprintf('\t'),'Al-26',sprintf('\t'),'quartz',sprintf('\t'),num2str(712408),sprintf('\t'),num2str(31238),sprintf('\t'),'KNSTD;'];

%Requires MATLAB R2021a or later to run Parser

%Created by Ann Rowan on 03/05/21
%Last modifed by Ann on 10/01/24
%Last modifed by Karlijn on 11/12/24


%Check if sample data contains gaps and skip samples if so
%sample_data = sample_data{1};
%Check sample data is the correct size for cosmo calculator
%a = find(sample_data == ':'); size(a);
%if a < 14; return; end

%text=input;
%Format sample data for input to cosmo calculator

%text = regexprep(input,':','\t');

text = regexprep(sample_data,':','\t');



%% Test

% text = ['Suth2007-A-13 -44.03550 168.47778 215.00000 std 5.0 2.65 1.0000 0 2005; ' ...
%    'Suth2007-A-13 Be-10 quartz 109000.000 11000.000 NIST_30600; ' ...
%    'Suth2007-A-14 -44.03550 168.47778 215.00000 std 5.0 2.65 1.0000 0 2005; ' ...
%    'Suth2007-A-14 Be-10 quartz 81000.000 10000.000 NIST_30600;'];

%text = ['Kapl2010-B-IS-06-15 -43.99190 170.04910 2001.00000 std 2.5 2.65 0.9730 0 2006; Kapl2010-B-IS-06-15 Be-10 quartz 234429.000 5413.000 07KNSTD; Kapl2010-B-IS-06-16 -43.99190 170.04910 1999.00000 std 1.9 2.65 0.9890 0 2006; Kapl2010-B-IS-06-16 Be-10 quartz 139381.000 2956.000 07KNSTD; Kapl2010-B-IS-06-16 Be-10 quartz 139331.000 3649.000 07KNSTD; Kapl2010-B-IS-06-17 -43.99010 170.05120 2016.00000 std 2.7 2.65 0.9830 0 2006; Kapl2010-B-IS-06-17 Be-10 quartz 198061.000 4543.000 07KNSTD; Kapl2010-B-IS-06-18 -43.99010 170.05130 2015.00000 std 3.0 2.65 0.9810 0 2006; Kapl2010-B-IS-06-18 Be-10 quartz 231801.000 6781.000 07KNSTD; Kapl2010-B-IS-06-19 -43.99050 170.05050 2006.00000 std 1.8 2.65 0.9880 0 2006; Kapl2010-B-IS-06-19 Be-10 quartz 229467.000 4796.000 07KNSTD; Kapl2010-B-IS-06-20 -43.99040 170.04950 2003.00000 std 2.9 2.65 0.9880 0 2006; Kapl2010-B-IS-06-20 Be-10 quartz 345737.000 7951.000 07KNSTD; Kapl2010-B-IS-06-21 -43.99000 170.04790 2004.00000 std 1.9 2.65 0.9880 0 2006; Kapl2010-B-IS-06-21 Be-10 quartz 226377.000 5251.000 07KNSTD; Kapl2010-B-IS-06-22 -43.99000 170.04750 1994.00000 std 2.7 2.65 0.9880 0 2006; Kapl2010-B-IS-06-22 Be-10 quartz 239078.000 5773.000 KNSTD; Kapl2010-B-IS-06-23 -43.99020 170.04730 1982.00000 std 1.5 2.65 0.9870 0 2006; Kapl2010-B-IS-06-23 Be-10 quartz 231041.000 5563.000 KNSTD; Kapl2010-B-IS-06-24 -43.99060 170.04750 1981.00000 std 2.5 2.65 0.9910 0 2006; Kapl2010-B-IS-06-24 Be-10 quartz 236520.000 5464.000 07KNSTD; Kapl2010-B-IS-06-25 -43.99090 170.04680 1955.00000 std 2.6 2.65 0.9860 0 2006; Kapl2010-B-IS-06-25 Be-10 quartz 245617.000 5340.000 KNSTD; Kapl2010-B-IS-06-26 -43.99080 170.04500 1917.00000 std 3.1 2.65 0.9820 0 2006; Kapl2010-B-IS-06-26 Be-10 quartz 202443.000 5155.000 07KNSTD; Kapl2010-B-IS-06-27 -43.99080 170.04430 1905.00000 std 4.4 2.65 0.9840 0 2006; Kapl2010-B-IS-06-27 Be-10 quartz 207131.000 5262.000 07KNSTD; Kapl2010-B-IS-06-28 -43.99160 170.04430 1878.00000 std 2.7 2.65 0.9840 0 2006; Kapl2010-B-IS-06-28 Be-10 quartz 206810.000 5865.000 07KNSTD; Kapl2010-B-IS-06-47 -43.99170 170.04210 1850.00000 std 1.1 2.65 0.9840 0 2006;'];

%% Calculations 

%Send sample info to cosmo calculator
url = "https://hess.ess.washington.edu/cgi-bin/matweb";
data_global = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no','text_block',text,'summary','yes');
data_local = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no','summary','yes',...
    'text_block',text,...
    'trace_string','nothing here but this is required',...
    'calib_name','nothing here either but this is required too',...
    'nuclide_name',parameters.nuclide,...
    'P_St',parameters.value_St,'delP_St',parameters.uncert_St,...
    'P_Lm',parameters.value_Lm,'delP_Lm',parameters.uncert_Lm,...
    'P_LSDn',parameters.value_LSDn,'delP_LSDn',parameters.uncert_LSDn);

%%
%Load the parser
import matlab.io.xml.dom.*

% Define the XML data to be parsed 
data_xml = {data_global, data_local};

%Define the struct in which to store all ages
results = struct('sample_ages', [], 'sum_val', [],'sum_int', [],'sum_ext', []);

for k = 1:length(data_xml)
    data= data_xml{k};
    
    xDoc = parseString(Parser, data);

    % Get all LSDn ages and SD for samples
    %name_elements = getElementsByTagName(xDoc, 'sample_name');
    LSDn_age_elements = getElementsByTagName(xDoc, 't10quartz_LSDn');
    LSDn_int_elements = getElementsByTagName(xDoc, 'delt10quartz_int_LSDn');
    LSDn_ext_elements = getElementsByTagName(xDoc, 'delt10quartz_ext_LSDn');

    no_samples = LSDn_age_elements.getLength;
    ages = struct('LSDn_age', [], 'LSDn_int', [], 'LSDn_ext', []);

    % Loop through each element and extract the values
    for i = 0:no_samples-1
        %ages(i+1).name = name_elements.item(i).getTextContent;
        ages(i+1).LSDn_age = str2double(LSDn_age_elements.item(i).getTextContent);
        ages(i+1).LSDn_int = str2double(LSDn_int_elements.item(i).getTextContent);
        ages(i+1).LSDn_ext = str2double(LSDn_ext_elements.item(i).getTextContent);
    end
    
    try
    % Store the LSDn data in the results struct
    results(k).sample_ages = ages;

    % Calculate landform age
    summary = getElementsByTagName(xDoc, 'summary').item(0);
    n10quartz = getElementsByTagName(summary, 'N10quartz').item(0);
    LSDn = getElementsByTagName(n10quartz, 'LSDn').item(0);

    % Get the content of the 'sumval' element within <LSDn>
    results(k).sum_val = str2double(getTextContent(getElementsByTagName(LSDn, 'sumval').item(0)));
    results(k).sum_int = str2double(getTextContent(getElementsByTagName(LSDn, 'sumdel_int').item(0)));
    results(k).sum_ext = str2double(getTextContent(getElementsByTagName(LSDn, 'sumdel_ext').item(0)));
    
    catch ME
        % Display error message and skip this calculation
        fprintf('Error processing landform age for data set %d: %s\n', k, ME.message);
        results(k).sum_val = NaN;
        results(k).sum_int = NaN;
        results(k).sum_ext = NaN; 
    end
end

% Access the results for global and local data
ages_global = results(1);
ages_local = results(2);




   
   
   