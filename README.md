# moraines
Scripts for analysis of big palaeoglaciological data

`iced_query.m` is a Matlab script to connect to ICE-D version 2 (https://version2.ice-d.org) and query the database to find sample data. The sample data are formatted for cosmo calculator (http://hess.ess.washington.edu).
<p>
  
`cosmo_calculator.m` is a Matlab script to use the output of the `iced_query.m` and send the sample data for calibration, returning ages and age errors.
</p>


`calibration_calculator.m` is a Matlab script to use the output of the query and send the sample data for calibration using alternative production rate parameters, returning ages and age errors. Calculation of alternative production rate parameters currently happens in `iced_query.m`.
</p>


`calibration_iced.m` is a Matlab script for calculating production rate parameters based on a calibration dataset available in the ICE-D database. Script retrieved from the ICE-D documentation (https://wiki.ice-d.org/pluginto:calculators).

