use strict;
use warnings;
use English '-no_match_vars';

use Cwd;
use File::Copy;
use File::Path;
use File::Basename;
use Getopt::Long;

# basepath
my $BASEPATH = getcwd ( $PROGRAM_NAME );

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


#&add_lang_styletranslation("PL","EN");
#&add_lang_typtranslation("PL","EN");
&remove_lang_styletranslation("PL");
&remove_lang_typtranslation("PL");

sub add_lang_styletranslation {

   # Set some variables
   my $newlang = shift;
   my $oldlang = shift;
   my $inputfile  = "$BASEPATH/style-translations-master";
   my $outputfile = "$BASEPATH/style-translations-master-new";
   my $line;
   
   # Open input and output files
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
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
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
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
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
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
           $counter = 1 ;
           foreach my $code ( sort ( keys %thisobjectstrings ) ) {
               print OUT "String$counter=$code,$thisobjectstrings{ $code }\n";
               $counter += 1;
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
   open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
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
           $counter = 1 ;
           foreach my $code ( sort ( keys %thisobjectstrings ) ) {
               print OUT "String$counter=$code,$thisobjectstrings{ $code }\n";
               $counter += 1;
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





