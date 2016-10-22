# Web Generator Toolkit

## Tools
A collection of scripts for correctly emulating web traffic using standard load-test harnesses, 
such as:
   
* [Apacher JMeter](http://jmeter.apache.org)
* [HP LoadRunner](http://www8.hp.com/us/en/software-solutions/loadrunner-load-testing/)
* [Selenium WebDriver](http://www.seleniumhq.org/projects/webdriver/)
* [Silk Performer](http://www.borland.com/en-GB/Products/Software-Testing/Performance-Testing/Silk-Performer)

and others.

## Installation and usage

Perform the following steps:

1. Create the environment variable `WEB_GEN_TOOLKIT` pointing to the local `bin` directory (Use `export` in Unix/Linux or `set` in Windows)
1. `cd` to the local directory `demo`  and execute `% run_perf_jmeter_records_select.pl`
1. `cd` into the subdirectory `select` and execute `% run_perf_arr_rt_jmeter_stats.pl`
1. More details are provided in [web-gen-toolkit_doc.pdf](https://github.com/DrQz/web-generator-toolkit/blob/master/web-gen-toolkit_doc.pdf)

<b>Note:</b> Be sure that the `GD.pm` module is in your Perl installation.


## References

1. J. F. Brady and N. J. Gunther, "How to Emulate Web Traffic Using Standard Load Testing Tools," 
Proceedings of CMG imPACt 2016, La Jolla, California. [Available online](http://arxiv.org/abs/1607.05356)

1. J. F. Brady,  "When Load Testing Large User Population Web Applications: The Devil is in The (Virtual) User Details," 
CMG Proceedings 2012, Las Vegas, Nevada.

1. D. M. Ciemiewicz, "What Do You Mean? Revisiting Statistics for Web Response Time Measurements,"
CMG Proceedings 2001, Anaheim, California.  [Available as PDF](http://www.perfdynamics.com/Classes/Materials/Ciemo-CMG2001.pdf) 

1. N. J. Gunther, [*Analyzing Computer System Performance with Perl::PDQ*](http://www.perfdynamics.com/iBook/ppa_new.html), Springerr-Verlag (2011)

1. N. J. Gunther, [*Guerrilla Capacity Planning: A Tactical Approach to Planning for Highly Scalable Applications and Services*](http://www.perfdynamics.com/iBook/gcap.html), 
Springer-Verlag (2007)

1. [Guerrilla Training Classes](http://www.perfdynamics.com/Classes/schedule.html)
