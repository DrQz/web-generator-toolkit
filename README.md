# Web Generator Toolkit

## Tools
A collection of scripts for correctly emulating web traffic using standard load-test harnesses, 
such as:
   
* [Grinder](http://grinder.sourceforge.net)
* [JMeter](http://jmeter.apache.org)
* [LoadRunner](http://www8.hp.com/us/en/software-solutions/loadrunner-load-testing/)
* [Selenium WebDriver](http://www.seleniumhq.org/projects/webdriver/)
* [Silk Performer](http://www.borland.com/en-GB/Products/Software-Testing/Performance-Testing/Silk-Performer)
* [Many more ...](http://www.developersfeed.com/20-best-performance-testing-tools/)


## Installation and usage

Perform the following steps:

1. Create the environment variable `WEB_GEN_TOOLKIT` pointing to the local `bin` directory (Use `export` in Unix/Linux or `set` in Windows)
1. `cd` to the local directory `demo`  and execute the command `% run_perf_jmeter_records_select.pl`
1. `cd` into the subdirectory `select` and execute the command `% run_perf_arr_rt_jmeter_stats.pl`

<b>Note:</b> Be sure that the `GD.pm` module is in your Perl installation.

More details are provided in [web-gen-toolkit_doc.pdf](https://github.com/DrQz/web-generator-toolkit/blob/master/web-gen-toolkit_doc.pdf)



## References

1. J. F. Brady and N. J. Gunther, "How to Emulate Web Traffic Using Standard Load Testing Tools," 
Proceedings of CMG imPACt 2016, La Jolla, California. ([Updated paper](https://github.com/DrQz/web-generator-toolkit/cmg16paper.pdf), [PPTX slides](https://github.com/DrQz/web-generator-toolkit/CMG16slides.pptx))

1. J. F. Brady,  "When Load Testing Large User Population Web Applications: The Devil is in The (Virtual) User Details," 
CMG Proceedings 2012, Las Vegas, Nevada. ([PDF](http://www.perfdynamics.com/Classes/Materials/Ciemo-CMG2001.pdf)) 

1. J. F. Brady,  "Traffic Generation Concepts: Random Arrivals," Unpublished notes, 2004.  ([PDF](http://www.perfdynamics.com/Classes/Materials/BradyTraffic.pdf))  

1. D. M. Ciemiewicz, "What Do You Mean? Revisiting Statistics for Web Response Time Measurements,"
CMG Proceedings 2001, Anaheim, California.  ([PDF](http://www.perfdynamics.com/Classes/Materials/Ciemo-CMG2001.pdf)) 

1. N. J. Gunther, [*Analyzing Computer System Performance with Perl::PDQ*](http://www.perfdynamics.com/iBook/ppa_new.html), Springer-Verlag (2011)

1. N. J. Gunther, "Emulating Web Traffic in Load Tests,"  [The Pith of Performance](http://perfdynamics.blogspot.com/2010/05/emulating-internet-traffic-in-load.html) (2010)

1. N. J. Gunther, [*Guerrilla Capacity Planning: A Tactical Approach to Planning for Highly Scalable Applications and Services*](http://www.perfdynamics.com/iBook/gcap.html), 
Springer-Verlag (2007)

1. N. J. Gunther, [Guerrilla Training Classes](http://www.perfdynamics.com/Classes/schedule.html)

1. B. Schroeder, A. Wierman, and M. Harchol-Balter, "Open Versus Closed: A Cautionary Tale," Proc. USENIX 3rd Symposium NSDI 2006, San Jose, California. 
([PDF](https://www.usenix.org/legacy/events/nsdi06/tech/full_papers/schroeder/schroeder.pdf)) 
