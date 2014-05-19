use strict;
use warnings;
use English '-no_match_vars';

use Cwd;
use File::Copy;
use File::Path;
use File::Basename;
use Getopt::Long;

# defined languages
my %typlanguages = (
    "xx", "0x00",    #	 unspecified
    "fr", "0x01",    #	 french
    "de", "0x02",    #	 german
    "nl", "0x03",    #	 dutch
    "en", "0x04",    #	 english
    "it", "0x05",    #	 italian
    "fi", "0x06",    #	 finnish
    "sv", "0x07",    #	 swedish
    "es", "0x08",    #	 spanish
    "eu", "0x09",    #	 basque
    "ca", "0x0a",    #	 catalan
    "gl", "0x0b",    #	 galician
    "cy", "0x0c",    #	 welsh
    "gd", "0x0d",    #	 gaelic
    "da", "0x0e",    #	 danish
    "no", "0x0f",    #	 norwegian
    "pt", "0x10",    #	 portuguese
    "sk", "0x11",    #	 slovak
    "cs", "0x12",    #	 czech
    "hr", "0x13",    #	 croatian
    "hu", "0x14",    #	 hungarian
    "pl", "0x15",    #	 polish
    "tr", "0x16",    #	 turkish
    "el", "0x17",    #	 greek
    "sl", "0x18",    #	 slovenian
    "ru", "0x19",    #	 russian
    "et", "0x1a",    #	 estonian
    "lv", "0x1b",    #	 latvian
    "ro", "0x1c",    #	 romanian
    "sq", "0x1d",    #	 albanian
    "bs", "0x1e",    #	 bosnian
    "lt", "0x1f",    #	 lithuanian
    "sr", "0x20",    #	 serbian
    "mk", "0x21",    #	 macedonian
    "bg", "0x22"     #	 bulgarian
);

# basepath
my $BASEPATH = getcwd ( $PROGRAM_NAME );
my $programName = basename ( $PROGRAM_NAME );


# command line parameters
my $help     = "";
my $newlanguage  = "";
my $rmlanguage   = "";
my $cplanguage   = "EN";

# =========================================================================
# 
# MAIN
#
# =========================================================================

# get the command line parameters
if ( ! GetOptions ( 'help|h|?' => \$help, 'add=s' => \$newlanguage, 'rm=s' => \$rmlanguage, 'cp=s' => \$cplanguage  ) ) {
  printf { *STDOUT } ( "ERROR:\n  Unknown option.\n\n\n" );
  show_usage ();
  exit(1);   
 }

# Show help if wished
if ( ( $help ) ) {
  show_help ();
  exit(0);
}

# neither add or remove choosen ?
unless ( ( $newlanguage ) || ( $rmlanguage ) ) {
  printf { *STDOUT } ( "ERROR:\n  choose one of the options do something.\n\n\n" );
  show_usage ();
  exit(1);   	
}

# both add and remove choosen ?
if ( ( $newlanguage ) && ( $rmlanguage ) ) {
  printf { *STDOUT } ( "ERROR:\n  choose either to add or remove languages... not both in one go.\n\n\n" );
  show_usage ();
  exit(1);   	
}

# Validate the langcodes entered and convert them to capitals
if ( $newlanguage ) {
	die "ERROR:\n  The LANGCODE for --add does not have the length 2\n" unless ( length($newlanguage) eq "2");
	$newlanguage =~ tr/a-z/A-Z/;
}
if ( $cplanguage ) {
	die "ERROR:\n  The LANGCODE for --cp does not have the length 2\n" unless ( length($cplanguage) eq "2");
	$cplanguage =~ tr/a-z/A-Z/;
}
if ( $rmlanguage ) {
	die "ERROR:\n  The LANGCODE for --rm does not have the length 2\n" unless ( length($rmlanguage) eq "2");
	$rmlanguage =~ tr/a-z/A-Z/;
}
if ( $newlanguage eq $ cplanguage ) {
  printf { *STDOUT } ( "ERROR:\n  --add can't be the same like --cp.\n\n\n" );
  show_usage ();
  exit(1);   	
}

# Looks like we want to add something
if ( $newlanguage ) {
	printf ("Adding language %s to the translation files (copying strings from %s)...\n", $newlanguage, $cplanguage);
    &add_lang_styletranslation($newlanguage,$cplanguage);
    &add_lang_typtranslation($newlanguage,$cplanguage);	
	printf ("Make sure to check the created new files with a diff tool before incorporating them\n");
    exit(0)
}

# Looks like we want to remove something
if ( $rmlanguage ) {
	printf ("Removing language %s from the translation files...\n", $rmlanguage);
    &remove_lang_styletranslation($rmlanguage);
    &remove_lang_typtranslation($rmlanguage);
	printf ("Make sure to check the created new files with a diff tool before incorporating them\n");
	exit(0)
}

#&add_lang_styletranslation("PL","EN");
#&add_lang_typtranslation("PL","EN");
#&remove_lang_styletranslation("PL");
#&remove_lang_typtranslation("PL");

# =========================================================================
# 
# Functions
#
# =========================================================================
sub add_lang_styletranslation {

   # Set some variables
   my $newlang = shift;
   my $oldlang = shift;
   my $inputfile  = "$BASEPATH/style-translations-master";
   my $outputfile = "$BASEPATH/style-translations-master-new";
   my $line;
   
   # Open input and output files
   printf ("   Reading source file %s\n", $inputfile);
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
   printf ("   Writing output to file %s\n", $outputfile);
   open OUT, "> $outputfile" or die "Can't open $outputfile : $!";
   
   # Read only the #define values from the file (ignoring trailing and tailing whitespace)
   while ( <IN> ) {
      
      # Get the line
      $line = $_;
      
      if ( $line =~ /^\s*\#define \$__(.*)__(([A-Z][A-Z])?)\s+(.*)/ ) {
         print OUT $line;
         
         if ( $2 eq $oldlang ) {
             print OUT "#define \$__$1__$newlang $4\n";
         }
      }
      else {
          print OUT $line;
      }
      
   }
   
   close IN;
   close OUT;
    
}

sub remove_lang_styletranslation {

   # Set some variables
   my $rmlang = shift;
   my $inputfile  = "$BASEPATH/style-translations-master";
   my $outputfile = "$BASEPATH/style-translations-master-new";
   my $line;
   
   # Open input and output files
   printf ("   Reading source file %s\n", $inputfile);
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
   printf ("   Writing output to file %s\n", $outputfile);
   open OUT, "> $outputfile" or die "Can't open $outputfile : $!";
   
   # Read only the #define values from the file (ignoring trailing and tailing whitespace)
   while ( <IN> ) {
      
      # Get the line
      $line = $_;
      
      if ( $line =~ /^\s*\#define \$__(.*)__(([A-Z][A-Z])?)\s+(.*)/ ) {
		  unless ( $2 eq $rmlang ) {
             # language doesn't match,  print out
             print OUT $line;
	      }
       } 
       else {
		   print OUT $line;
	   }     
   }
   
   close IN;
   close OUT;
    
}

sub add_lang_typtranslation {
    
   # Set some variables
   my $newlang = shift;
   my $oldlang = shift;
   my $inputfile  = "$BASEPATH/typ-translations-master";
   my $outputfile = "$BASEPATH/typ-translations-master-new";
   my $inputline;
   my %thisobjectstrings = ();
   my $counter = 0;

   # get the codes for the needed languages
   $newlang =~ tr/A-Z/a-z/;
   $oldlang =~ tr/A-Z/a-z/;
   my $newlangcode = $typlanguages{ $newlang };
   my $oldlangcode = $typlanguages{ $oldlang };
      
   # Open input and output files
   printf ("   Reading source file %s\n", $inputfile);
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
   printf ("   Writing output to file %s\n", $outputfile);
   open OUT, "> $outputfile" or die "Can't open $outputfile : $!";

   # Read through the inputfile
   while ( <IN> ) {
       
       $inputline = $_;
       
       # New Object starts
       if ( $inputline =~ /^\[_(line|polygon|point)\]$/ ) {
           
           # empty the temporary variables
           %thisobjectstrings = ();

           print OUT $inputline;
           
           # Read the rest of this object
           while ( <IN> ) {
               
               $inputline = $_;
               
               last if ( $inputline =~ /^\[end\]/ ) ;

               # Read the strings
               if ( $inputline =~ /^String[0-9]*=(0x[0-9A-F]{2}),(.*)$/i ) {
                  $thisobjectstrings{ $1 } = $2;
            
                  
                  # is it the language we copy from ?
                  if ( $1 eq $oldlangcode ) {
                      $thisobjectstrings{ $newlangcode } = $2;
                  }
               }
               else {
                   print OUT $inputline;
               }
           }
           
           # Print the strings again in new and correct order
           # Counter taken away for easier handling of new languages
           #$counter = 1 ;
           foreach my $code ( sort ( keys %thisobjectstrings ) ) {
               #print OUT "String$counter=$code,$thisobjectstrings{ $code }\n";
               print OUT "String=$code,$thisobjectstrings{ $code }\n";
               #$counter += 1;
           }
           
           # End the Object properly
           print OUT $inputline;
           
       }
       else {
           print OUT $inputline;
       }
   }
   
   close IN;
   close OUT;

}

sub remove_lang_typtranslation {
    
   # Set some variables
   my $rmlang = shift;
   my $inputfile  = "$BASEPATH/typ-translations-master";
   my $outputfile = "$BASEPATH/typ-translations-master-new";
   my $inputline;
   my %thisobjectstrings = ();
   my $counter = 0;

   # get the codes for the needed languages
   $rmlang =~ tr/A-Z/a-z/;
   my $rmlangcode = $typlanguages{ $rmlang };
      
   # Open input and output files
   printf ("   Reading source file %s\n", $inputfile);
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
   printf ("   Writing output to file %s\n", $outputfile);
   open OUT, "> $outputfile" or die "Can't open $outputfile : $!";

   # Read through the inputfile
   while ( <IN> ) {
       
       $inputline = $_;
       
       # New Object starts
       if ( $inputline =~ /^\[_(line|polygon|point)\]$/ ) {
           
           # empty the temporary variables
           %thisobjectstrings = ();

           print OUT $inputline;
           
           # Read the rest of this object
           while ( <IN> ) {
               
               $inputline = $_;
               
               last if ( $inputline =~ /^\[end\]/ ) ;

               # Read the strings
               if ( $inputline =~ /^String[0-9]*=(0x[0-9A-F]{2}),(.*)$/i ) {
                              
                  # is it the language we have to remove from ?
                  if ( $1 ne $rmlangcode ) {
                      $thisobjectstrings{ $1 } = $2;
                  }
               }
               else {
                   print OUT $inputline;
               }
           }
           
           # Print the strings again in new and correct order
           # Counter taken out
           #$counter = 1 ;
           foreach my $code ( sort ( keys %thisobjectstrings ) ) {
               print OUT "String=$code,$thisobjectstrings{ $code }\n";
               #print OUT "String$counter=$code,$thisobjectstrings{ $code }\n";
               #$counter += 1;
           }
           
           # End the Object properly
           print OUT $inputline;
           
       }
       else {
           print OUT $inputline;
       }
   }
   
   close IN;
   close OUT;

}


# -----------------------------------------
# Show short usage
# -----------------------------------------
sub show_usage {

  # Print the Usage
  printf { *STDOUT } (
    "Usage:\n"
      . "perl $programName [--add=LANGCODE] [--cp=LANGCODE]\n"
      . "  or\n"
      . "perl $programName [--rm=LANGCODE]\n\n"
      . "  or for getting help:\n"
      . "  perl $programName -? | -h\n"
      . "\n\n"
  );

}


# -----------------------------------------
# Show complete help
# -----------------------------------------
sub show_help {

  # Show the sort Usage
  show_usage ();
  
  # Print the details of the help
  printf { *STDOUT } (
      "Examples:\n"
      . "perl $programName --add=PL --cp=EN\n"
      . "           adds language PL to the translation files and copies from EN\n"
      . "perl $programName --rm=PL\n"
      . "           removes language PL from the translation files\n\n"
      . "Options:\n"
      . "--add=<LANGCODE>\n"
      . "      Adds the language with the specified LANGCODE to both the\n"
      . "      translation files.\n"
      . "--cp=<LANGCODE>\n"
      . "      While adding: copies the strings from the specified LANGCODE.\n"
      . "      Default Value: EN\n"
      . "--rm=<LANGCODE>\n"
      . "      Removes the language with the specified LANGCODE from both the\n"
      . "      translation files"
      . "\n\n\n"
   );
  
}



