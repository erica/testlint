# testlint

Sometimes little thrown-together solutions create greater value than their aesthetics would promise. 

###Setup

* Compile
* Add to Swift project build phases (Target > Build Phases >  or use directly at the command line.

![Setup](http://i.imgur.com/EIApOcy.jpg)

When you do not add arguments, the utility looks for an .xcodeproj folder in the same directory. Run it this way at the top level of a project or as a build script.

No dependencies.

###Options:

    Usage: /Users/ericasadun/bin/testlint options file...
        help:                       -help
        skip strict colon checks:   -relaxcolons  (Standard Swift style)
        skip Allman check:          -allmanrocks  (Standard Swift style)
        skip all style checks:      -nostyle      (Standard Swift style)
        skip cast/unwrap checks:    -nocast       (Extra strict)
        skip hygiene checks:        -nohygiene    (Extraneous spacing)
        access modifier checks:     -access       (False positives)
        enable constructor checks:  -constructors (False positives)
    
    Use 'NOTE: ', 'ERROR: ', 'WARNING: ', and FIXME to force emit
    Use 'nwm' to skip individual line processing: // nwm


###Future directions:

For any of the nuanced features (specifically constructors and public access checks), this tool is either leaky like a sieve or creating false positives all over the place. I'm exploring possibilities but even with these issues, I'm using the utility regularly and am happy with the help it offers.


