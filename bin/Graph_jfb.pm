package Graph;

=head1 NAME

Graph - Create PNG graphs from given data (JFB).

=head1 SYNOPSIS

	use Graph;
	$img = new Graph;
	$img->data(123,"value 1");
	$img->title("Example Graph");
	...
        $img->output("filename.png");

=head1 DESCRIPTION

This module lets you create charts from data and output them
to a PNG image.  It uses GD.pm to do the actual image manipulation.
The goal of this module is to let you have as much or as little
control over the resulting graph as you want.  You can just insert
a few data points and get a graph, or control every aspect of the
graph layout and contents, depending on your needs.  It is intended
for other modules with different graph types (pie chart, line 
graph, etc) to be derived from this class.

Send the following messages to your Graph object to control the
results:

=over 5

=item data ( value , label )

Add a data point to the graph.  Value is required, label is
optional.

=item set_color ( name , red , green , blue )

Make a color available in other methods.  Give it a name and
red, green, and blue values from 0-255, and you can then 
use the name anywhere a color is required.

=item get_color ( name )

Return a (red,green,blue) array for the given color name

=item write_to_file ( filename )

Write all current options to a filename for easy retrieval later

=item load_from_file ( filename )

Read in all options for a graph from a file saved by write_to_file

=item output ( filename )

Output the graph image.  With no arguments, the binary image 
data is returned.  GD.pm does not support this on Win32, so with 
no arguments the data will be printed by STDOUT.  With a filename
as an argument, the png image will be saved to disk.

=back

The following methods return the value of the property if given no
argument, or set it if given an argument.  Fonts must be one of
gdTinyFont, gdSmallFont, gdMediumBoldFont, or gdLargeFont.  Colors
must have either been defined or be one of the default colors.

=over 5

=item width, height

Force the image to be a certain size.  This will change other values
that you may set in order to squeeze or expand everything to the right
size.

=item title

Text to center at the top of the image as the title.

=item title_font

Font to use for title.

=item title_font_color

Color to use for title.

=item title_padding

The number of pixels to use as 'padding' around the title.

=item subtitle

Text to center below the title.
Also uses subtitle_font, subtitle_font_color, subtitle_padding.

=item keys_label

Label to put on the X axis, below the keys.
Also uses keys_label_font, keys_label_font_color, keys_label_padding.

=item values_label

Label to put on the Y acis, next to the values.
Also uses values_label_font, values_label_font_color, values_label_padding.

=item keys_font, keys_font_color, keys_padding

Control the properties of the key labels on the X axis.

=item values_font, values_font_color, values_padding

Control the properties of value labels on the Y axis.

=item value_label_font, value_label_font_color, value_label_padding

Currently unused.  Will be used to label the value of each separate
bar on the graph.

=item value_format

Controls formatting of value labels on the Y axis.  Must be in the format
of x.y, where x controls how many digits are before the decimal point, and
y controls how many digits appear after the decimal point.  If followed by
a "k" or "K", all values are divided by 1,000.  If followed by an "m" or "M"
all values are divided by 1,000,000.  Any extra text before or after the
x.y is retained.

For example, if you are graphing money, you may use a format like "$.2", so a
"$" precedes all numbers, and they are cut off at two decimal places.  You can
also use labels, such as ".3 cm" to label values as centimeters.

=item value_min, value_max

Set these values to force the scale of the Y axis.  Any values lower than
value_min will not be graphed, and anything greater than value_max will go
off the chart.

=item value_labels

Label on certain values on the Y axis, rather than values at an even interval.
If you don't want any values at all to be labeled, set this to 'none'.

=item bgcolor

A color to use as the background.  Ignored if background image is given.

=item background_image

The full path to an image to be used as the background.  The image will be
tiled, and bgcolor will be ignored.

=item color_list

A comma-separated list of colors to cycle through for the colors of the bars.
If given "red,green,blue", for example, the first bar will be red, the second
will be green, and the third will be blue.  The fourth will then go back to
red and start over.

=item line_width

The width of the axis lines.  Currently not used.

=item line_color

The color of the axis lines.

=item top_gutter, right_gutter, bottom_gutter, left_gutter

The number of pixels to leave empty on each side of the image.

=item bar_size

The width in pixels of each bar in the chart.  If a width is forced, this
will be scaled appropriately.

=item bar_spacing

The width in pixels between each bar in the chart.  If a width is forced,
this will be scaled appropriately.

=item bar_shadow_depth

The number of pixels down and to the right that a shadow will be placed
behind each bar.  Set to 0 for no shadow.

=item bar_shadow_color

The color of the shadows for each bar.

=item tick_number

The number of 'ticks' for values to be placed on the Y axis, between the
top and bottom values.  Ignored if value_labels is set.

=item tick_width

How wide each 'tick' is in pixels.

=item tick_padding

The number of empty pixels to be placed next to each 'tick'.

=back

=head1 THANKS

This module is made possible by the B<excellent> work done by:

=over 5

=item Tom Boutell

Author of the original GD libraries written in C.
http://www.boutell.com/

=item Lincoln Stein

Author of GD.pm, the Perl interface to GD.
http://www-genome.wi.mit.edu/~lstein/

=item Dave Roth

Author of the Win32 port of GD.
http://www.roth.net/

=back

=head1 NOTES

This is my first "real" module with pod and all.  Keep that in mind :)

Set Graph::debug = 1 for some debugging info.

=head1 AUTHOR

Matt Kruse <mkruse@netexpress.net>

(Modified by JFB to create .png Vs .gif images)

=cut

use GD;
use Carp;
use Config; # to check whether NT or unix

$VERSION = '0.9';

# -------------------------------------------------------------------
# Create a new graph object and load all defaults
# -------------------------------------------------------------------
sub new {
	my $class = shift;
	my $self = {};
	bless $self,$class;
	$self->load_defaults();
	return $self;
	}

# -------------------------------------------------------------------
# data: Add data to the @data array in a custom way
# returns: # of elements in data
# -------------------------------------------------------------------
sub data {
	my $self = shift;
	my $data = shift;
	unless (defined $data) { die "Missing data in add_data\n"; }
	my $label= shift;

	push( @{$self->{data}}   , $data );
	push( @{$self->{labels}} , $label);
	return $#{$self->{data}};
}

# -------------------------------------------------------------------
# set_color: define an RGB color with a name
# -------------------------------------------------------------------
sub set_color {
	my $self = shift;

	my $name = shift or croak "missing name in call to set_color\n";
	my $red  = shift; 
	my $green= shift; 
	my $blue = shift; 

	unless (defined $red) { croak "Missing red value in set_color\n"; }
	unless (defined $green) { croak "Missing green value in set_color\n"; }
	unless (defined $blue) { croak "Missing blue value in set_color\n"; }

	# Make sure color values are valid
	foreach ($red,$green,$blue) {
		if (($_ < 0) || ($_ > 255)) {
			croak "Value out of range in set_color\n";
			}
		}
	@{$self->{'colors'}->{$name}} = ( $red,$green,$blue );
}

# -------------------------------------------------------------------
# get_color: return an array or R,G,B for a color name
# -------------------------------------------------------------------
sub get_color {
	my $self = shift;
	my $name = shift or croak "missing color in call to get_color\n";
	return @{$self->{'colors'}{$name}};
	}

# -------------------------------------------------------------------
# load_from_file: Load object properties from a file
# File format is:
#   key = value
#   key = ARRAY:value,value,value
# -------------------------------------------------------------------
sub load_from_file { 
	my $self = shift;
	my $filename = shift or croak "Missing filename in load_from_file\n";
	my ($key,$value);

	open(IN,$filename) or croak "Couldn't open $filename in load_from_file\n";
	while(<IN>) {
		next if /^#/;   # ignore comments
		s/\s*\#.*$//;   # Cut out comments
		($key,$value) = /^(\w*)\s*=\s*(.*)/;
		next unless $key;
		if ($value =~ /^ARRAY/) {
			$value =~ s/^ARRAY:\s*//;
			@{$self->{$key}} = split(/,/ ,$value);
			}
		else {
        	$self->{$key}=$value;
			}
		}
	close(IN);
}

# -------------------------------------------------------------------
# AUTOLOAD: used for general get/set methods
# You can override this routine, of course.
# $var = property()  # get
# property('value')  # set
# -------------------------------------------------------------------
sub AUTOLOAD {
	my $self = shift;
	my $value = shift;
	my $property = $AUTOLOAD;

	# If a value is present, set the property
	if (defined $value) {
		$property =~ s/^.*?\:\://;
		print "Setting $property to $value\n" if $debug;
		$self->{$property} = $value;
		return $value;
		}
	# Otherwise just return the current setting
	else {
		return $self->{$property};
		}
}

# -------------------------------------------------------------------
# defaults: set default values unless they are already filled
# $self->defaults(key,value,key,value,...);
# -------------------------------------------------------------------
sub defaults {
	my $self = shift;
	my ($key,$val);

	while ($key = shift) {
		$val = shift;
		return unless (defined $val);
		next if (defined $self->{$key});
		$self->{$key} = $val;
		}
	}

# -------------------------------------------------------------------
# write_config_file: 
# -------------------------------------------------------------------
sub write_to_file { 
	my $self = shift;
	my $filename = shift or croak "Missing filename in write_config_file\n";

	open(OUT,"> $filename") or croak "Can't open $filename for writing in write_config_file\n";
	foreach (sort keys %{$self}) {
		if (ref($self->{$_}) =~ /^ARRAY/) {
			print OUT "$_ = ARRAY:", join (',' ,@{$self->{$_}}), "\n";
			}
		else {
			print OUT "$_ = $self->{$_}\n";
			}
		}
	close(OUT);
    }

# -------------------------------------------------------------------
# default_colors: define some default colors with names
# -------------------------------------------------------------------
sub default_colors {
	my $self = shift;
	$self->set_color("white",255,255,255);
	$self->set_color("black",0,0,0);
	$self->set_color("red",255,0,0);
	$self->set_color("green",0,255,0);
	$self->set_color("blue",0,0,255);
	$self->set_color("dimgrey",84,84,84);
	$self->set_color("gray",191,191,191);
	$self->set_color("lightgray",168,168,168);
	$self->set_color("vlightgray",204,204,204);
	$self->set_color("aquamarine",112,219,147);
	$self->set_color("blueviolet",158,94,158);
	$self->set_color("brown",165,42,42);
	$self->set_color("cadetblue",94,158,158);
	$self->set_color("coral",255,126,0);
	$self->set_color("cornflowerblue",66,66,110);
	$self->set_color("darkgreen",47,79,47);
	$self->set_color("darkolivegreen",79,79,47);
	$self->set_color("darkorchid",153,49,204);
	$self->set_color("darkslateblue",107,35,142);
	$self->set_color("darkslategray",47,79,79);
	$self->set_color("darkslategrey",47,79,79);
	$self->set_color("darkturquoise",112,147,219);
	$self->set_color("firebrick",142,35,35);
	$self->set_color("forestgreen",35,142,35);
	$self->set_color("gold",204,126,49);
	$self->set_color("goldenrod",219,219,112);
	$self->set_color("greenyellow",147,219,112);
	$self->set_color("indianred",79,47,47);
	$self->set_color("khaki",158,158,94);
	$self->set_color("lightblue",191,216,216);
	$self->set_color("lightsteelblue",142,142,188);
	$self->set_color("limegreen",49,204,49);
	$self->set_color("maroon",142,35,107);
	$self->set_color("mediumaquamarine",49,204,153);
	$self->set_color("mediumblue",49,49,204);
	$self->set_color("mediumforestgreen",107,142,35);
	$self->set_color("mediumgoldenrod",233,233,172);
	$self->set_color("mediumorchid",147,112,219);
	$self->set_color("mediumseagreen",66,110,66);
	$self->set_color("mediumturquoise",112,219,219);
	$self->set_color("mediumvioletred",219,112,147);
	$self->set_color("midnightblue",47,47,79);
	$self->set_color("navy",35,35,142);
	$self->set_color("navyblue",35,35,142);
	$self->set_color("orange",255,127,0);
	$self->set_color("orchid",219,112,219);
	$self->set_color("palegreen",142,188,142);
	$self->set_color("pink",188,142,142);
	$self->set_color("plum",233,172,233);
	$self->set_color("salmon",110,66,66);
	$self->set_color("seagreen",35,142,107);
	$self->set_color("sienna",142,107,35);
	$self->set_color("skyblue",49,153,204);
	$self->set_color("steelblue",35,107,142);
	$self->set_color("tan",219,147,112);
	$self->set_color("thistle",216,191,216);
	$self->set_color("turquoise",172,233,233);
	$self->set_color("violet",79,47,79);
	$self->set_color("violetred",204,49,153);
	$self->set_color("wheat",216,216,191);
	$self->set_color("yellowgreen",153,204,49);
	$self->set_color("summersky",56,175,221);
	$self->set_color("richblue",89,89,170);
	$self->set_color("brass",181,165,66);
	$self->set_color("copper",183,114,51);
	$self->set_color("bronze",140,119,35);
	$self->set_color("bronze2",165,124,61);
	$self->set_color("silver",229,232,249);
	$self->set_color("brightgold",216,216,25);
	$self->set_color("oldgold",206,181,58);
	$self->set_color("feldspar",209,145,117);
	$self->set_color("quartz",216,216,242);
	$self->set_color("neonpink",255,109,198);
	$self->set_color("darkpurple",135,30,119);
	$self->set_color("neonblue",76,76,255);
	$self->set_color("coolcopper",216,135,25);
	$self->set_color("mandarinorange",226,119,51);
	$self->set_color("lightwood",232,193,165);
	$self->set_color("mediumwood",165,127,99);
	$self->set_color("darkwood",132,94,66);
	$self->set_color("spicypink",255,28,173);
	$self->set_color("semisweetchoc",107,66,38);
	$self->set_color("bakerschoc",91,51,22);
	$self->set_color("flesh",244,204,175);
	$self->set_color("newtan",234,198,158);
	$self->set_color("newmidnightblue",0,0,155);
	$self->set_color("verydarkbrown",89,40,35);
	$self->set_color("darkbrown",91,63,51);
	$self->set_color("darktan",150,104,79);
	$self->set_color("greencopper",81,124,117);
	$self->set_color("dkgreencopper",73,117,109);
	$self->set_color("dustyrose",132,99,99);
	$self->set_color("huntersgreen",33,94,79);
	$self->set_color("scarlet",140,22,22);
} # end of default_colors

# -------------------------------------------------------------------
# GD-Specific Methods and Properties
# -------------------------------------------------------------------
# Build a hash table pointing to the font functions
%fonts=(
	"gdSmallFont"=>gdSmallFont(),
	"gdLargeFont"=>gdLargeFont(),
	"gdTinyFont"=>gdTinyFont(),
	"gdMediumBoldFont"=>gdMediumBoldFont()
	);

# Build up a table of font widths and heights for spacing purposes
($gdSmallFont{w},$gdSmallFont{h}) = (gdSmallFont->width,gdSmallFont->height);
($gdLargeFont{w},$gdLargeFont{h}) = (gdLargeFont->width,gdLargeFont->height);
($gdMediumBoldFont{w},$gdMediumBoldFont{h}) = (gdMediumBoldFont->width,gdMediumBoldFont->height);
($gdTinyFont{w},$gdTinyFont{h}) = (gdTinyFont->width,gdTinyFont->height);

# Where the GD color pointers will be stored
%colors = ( );

# -------------------------------------------------------------------
# format: make values more readable, accoriding to setting
# -------------------------------------------------------------------
sub format {
	my $self = shift;
	my $value = shift;
	unless (defined $self->{"value_format"}) { return $value; }
	my $format = $self->{"value_format"};
	($front,$precision,$back) = ($format =~ /([^\-\d]*)\.(\d*)(.*)/);
	if (($back eq 'k') or ($back eq 'K')) {
		$value = $value/1000;
		}
	if (($back eq 'm') or ($back eq 'M')) {
		$value = $value/1000000;
		}
	$value = sprintf("%0.${precision}f",$value);
	$value = $front . $value . $back;
	return $value;
}

# -------------------------------------------------------------------
# output: return the binary graph image data
# This routine should be overridden in derived graph classes
#
# The default graph is a simple bar chart
# -------------------------------------------------------------------
sub output {
	my $self = shift;
	my $filename = shift;
	my ($maxlength,$maxvalue,$minlength,$minvalue);
	my ($canvasl,$canvasr,$canvast,$canvasb,$canvaswidth,$canvasheight);

	# Set up all the default values
	$self->defaults(
		"title_font_color"		,	"black",
		"title_font"			,	"gdLargeFont",
		"title_padding"			,	"5",
		"subtitle_font_color"	,	"black",
		"subtitle_font"			,	"gdSmallFont",
		"subtitle_padding"		,	"3",
		"keys_label_padding"	,	"5",
		"keys_label_font"		,	"gdLargeFont",
		"keys_label_font_color"	,	"black",
		"keys_font"				,	"gdMediumBoldFont",
		"keys_font_color"		,	"black",
		"keys_padding"			,	"2",
		"values_label_padding"	,	"5",
		"values_label_font"		,	"gdLargeFont",
		"values_label_font_color",	"black",
		"values_font"			,	"gdSmallFont",
		"values_font_color"		,	"black",
		"values_padding"		,	"2",
		"value_label_padding"	,	"2",
		"value_label_font"		,	"gdMediumBoldFont",
		"value_label_font_color",	"black",
		"bgcolor"				,	"white",
		"color_list"			,	"wheat",
		"line_width"			,	"1",
		"line_color"			,	"black",
		"right_gutter"			,	"10",
		"top_gutter"			,	"10",
		"left_gutter"			,	"10",
		"bottom_gutter"			,	"10",
		"bar_size"				,	"20",
		"bar_spacing"			,	"8",
		"bar_shadow_depth"		,	"2",
		"bar_shadow_color"		,	"black",
		"tick_width"			,	"5",
		"tick_number"			,	"3",
		"tick_padding"			,	"2"
		);

	# Create an array of colors from color_list
	my (@color_list) = split(/\,/,$self->{"color_list"});

	# Figure out the max and min values on the Y axis
	undef $minvalue;
	undef $maxvalue;
	foreach (@{$self->{"data"}}) {
		if (defined $minvalue) {
			if ($_ < $minvalue) { $minvalue = $_;  }
			}
		else {
			$minvalue = $_;
			}
		if (defined $maxvalue) {
			if ($_ > $maxvalue) { $maxvalue = $_; }
			}
		else {
			$maxvalue = $_;
			}
		}
	print "Minimum Data value: $minvalue\n" if $debug;
	print "Maximum Data value: $maxvalue\n" if $debug;
	unless (defined $self->{"value_min"}) {
		if ( ($maxvalue-$minvalue) == 0) {
			$self->{"value_min"} = $minvalue - ($minvalue * .05);
			}
		else {
			$self->{"value_min"} = $minvalue - ( ($maxvalue-$minvalue) * .05 );
			}
		}
	unless (defined $self->{"value_max"}) {
		if ( ($maxvalue-$minvalue) == 0) {
			$self->{"value_max"} = $maxvalue + ($maxvalue * .05);
			}
		else {
			$self->{"value_max"} = $maxvalue + ( ($maxvalue-$minvalue) * .05 );
			}
		}
	print "Minimum Y value set to $self->{value_min}\n" if $debug;
	print "Maximum Y value set to $self->{value_max}\n" if $debug;

	# Figure out how to handle the value labels
	# if the value_labels are set to specific values, use those
	my @value_labels;
	if (defined $self->{"value_labels"}) {
		if ($self->{"value_labels"} eq 'none') {
			(@value_labels) = ();
			}
		else {
			(@value_labels) = split(/\,/,$self->{"value_labels"});
			}
		}
	# Since specific values weren't given, figure out which ones
	#    will be used
	else {
		push(@value_labels,$minvalue);
		foreach (1..$self->{"tick_number"}) {
			push(@value_labels,$minvalue+(($maxvalue-$minvalue)/($self->{"tick_number"}+1))*$_);
			}
		push(@value_labels,$maxvalue);
		}

	# Find the margins around the actual graphing canvas
	my ($top_margin, $right_margin, $bottom_margin, $left_margin);
	# Find the top margin
	$top_margin = $self->{"top_gutter"};
	if ($self->{"title"}) {
		$top_margin += $self->{"title_font"}->{"h"};
		$top_margin += $self->{"title_padding"}*2;
		}
	if ($self->{"subtitle"}) {
		$top_margin += $self->{"subtitle_font"}->{"h"};
		$top_margin += $self->{"subtitle_padding"}*2;
		}

	# Find the left margin
	$left_margin = $self->{"left_gutter"};
	if (defined $self->{"values_label"}) {
		$left_margin += $self->{"values_label_font"}->{"h"};
 		$left_margin += ($self->{"values_label_padding"} * 2);
		}
	if ($#value_labels >= 0) {
		$maxlength=0;
		foreach (@value_labels) {
			if ( length($self->format($_)) > $maxlength ) {
				$maxlength=length($self->format($_)); 
				}
			}
		$maxlength = $self->{"values_font"}->{"w"} * $maxlength;
		$left_margin += $maxlength + ($self->{"values_padding"} * 2);
		$left_margin += $self->{"tick_width"};
		$left_margin += $self->{"tick_padding"};
		}
	$left_margin += $self->{"line_width"};

	# Find the right margin
	$right_margin = $self->{"right_gutter"};

	# Find the bottom margin
	$bottom_margin = $self->{"bottom_gutter"};
	if (defined $self->{"keys_label"}) { 
		$bottom_margin += $self->{"keys_label_font"}->{"h"};

		$bottom_margin += $self->{"keys_label_padding"}*2;
		}
	if ($#{$self->{"labels"}} >= 0) {
		$maxlength=0;
		foreach (@{$self->{"labels"}}) {
			if ( length($_) > $maxlength ) { 
				$maxlength=length($_); 
				}
			}
		$maxlength = $self->{"keys_font"}->{w}*$maxlength;
		$bottom_margin += $maxlength + ($self->{"keys_padding"} * 2);
		}
	$bottom_margin += $self->{"line_width"};

	# If width and height are given, use those.  If not, find good
	#    ones to use.
	my ($bar_spacing_l);
	if (defined $self->{"width"}) {
		$canvaswidth = $self->{"width"} - $left_margin - $right_margin;
		if ($canvaswidth < 1) {
			croak "Image not big enough to fit chart!\n";
			}
		print "canvaswidth = $canvaswidth\n" if $debug;
		my ($ratio) = ( int($canvaswidth/($#{$self->{"data"}}+1)) / 
		                ($self->{"bar_size"}+$self->{"bar_spacing"})
		              );
		print "Bar size scaling ratio = $ratio\n" if $debug;
		print "   Old bar size = $self->{bar_size}\n" if $debug;
        $self->{"bar_size"} = int($self->{"bar_size"} * $ratio);
		print "   New bar size = $self->{bar_size}\n" if $debug;
		print "   Old bar spacing = $self->{bar_spacing}\n" if $debug;
		$self->{"bar_spacing"} = int($canvaswidth/($#{$self->{"data"}}+1))
		                         - $self->{"bar_size"};
		print "   New bar spacing = $self->{bar_spacing}\n" if $debug;
		$bar_spacing_l = int($self->{"bar_spacing"}/2);
		}
	else {
		$self->{"width"} = $left_margin + (($#{$self->{"data"}}+1)*($self->{"bar_size"}+$self->{"bar_spacing"})) + $right_margin;
		$canvaswidth = $self->{"width"} - $left_margin - $right_margin;
		$bar_spacing_l = int($self->{"bar_spacing"}/2);
		}
	if ($self->{"height"}) {
		$canvasheight = $self->{"height"} - $top_margin - $bottom_margin;
		}
	else {
		$canvasheight = 250;
		$self->{"height"} = $top_margin + $canvasheight + $bottom_margin;
		}
	$canvasl = $left_margin;
	$canvasr = $self->{"width"} - $right_margin;
	$canvast = $top_margin;
	$canvasb = $self->{"height"} - $bottom_margin;

	$self->default_colors;
	# Make the new image, get colors, fill it
	$img = new GD::Image($self->{"width"},$self->{"height"});
	print "Image Created: $self->{width} x $self->{height}\n" if $debug;
	# Allocate colors in the GD object
	my ($name,$red,$green,$blue);
	foreach $name (keys %{$self->{'colors'}}) {
		($red,$green,$blue) = @{$self->{'colors'}->{$name}};
		$colors{$name} = $img->colorAllocate($red,$green,$blue);
		}
	print "Colors Allocated\n" if $debug;

	# Put in the background image if given, or just the bgcolor
	if (defined $self->{"background_image"}) {
		my $bg;
		unless (-e "$self->{background_image}") { croak "Background image not found\n"; }
		open(IMG,$self->{"background_image"}) or die "Can't open background image $!\n";
		binmode IMG;
                $bg = newFromPng GD::Image(IMG) || die "Can't open background image! $! x\n";
                close(IMG);
		$img->setTile($bg);
		$img->fill(1,1,gdTiled);
		}
	else {
		$img->fill(1,1,$colors{$self->{"bgcolor"}});
		}

	# Draw Axis
	$img->line($canvasl-1,$canvasb+1,$canvasr+1,$canvasb+1,$colors{$self->{"line_color"}});
	$img->line($canvasl-1,$canvast,$canvasl-1,$canvasb+1,$colors{$self->{"line_color"}});

	# Draw the bars
	my ($offset) = $self->{"bar_size"} + $self->{"bar_spacing"};
	my ($i,$val,$color,$x1,$x2,$y1,$y2);
	foreach $i (0.. $#{$self->{"data"}}) {
		$color=$color_list[int($i % ($#color_list + 1))];
		$x1 = $canvasl + ( $offset * $i ) + $bar_spacing_l;
		$x2 = $canvasl + ( $offset * $i ) + $bar_spacing_l + ($self->{"bar_size"});
		$y1 = $canvasb - int( (($self->{"data"}->[$i] - $self->{"value_min"}) 
		                     / ($self->{"value_max"} - $self->{"value_min"}))
		                     * $canvasheight );
		$y2 = $canvasb;
		$img->filledRectangle($x1+$self->{"bar_shadow_depth"},$y1+$self->{"bar_shadow_depth"},
		                      $x2+$self->{"bar_shadow_depth"},$y2,$colors{$self->{"bar_shadow_color"}});
		$img->filledRectangle($x1,$y1,$x2,$y2,$colors{$color});

		# Label the bar
		$img->stringUp($fonts{$self->{"keys_font"}},
		               $x1 + int(($self->{"bar_size"} - $self->{"keys_font"}->{"h"})/2),
					   $canvasb + ($self->{"keys_font"}->{w}*length($self->{"labels"}->[$i])) + $self->{"keys_padding"},
		               "$self->{labels}->[$i]",
					   $colors{$self->{"keys_font_color"}});
		}

	# Put in the keys label
	if (defined $self->{"keys_label"}) {
		$img->string($fonts{$self->{"keys_label_font"}},
		             int( $canvasl + (($canvaswidth - ($self->{"keys_label_font"}->{w}*length($self->{"keys_label"})) )/2)),
					 $self->{"height"} - $self->{"bottom_gutter"} - $self->{"keys_label_font"}->{h} - $self->{"keys_label_padding"},
					 "$self->{keys_label}",
					 $colors{$self->{"keys_label_font_color"}}
					 );
		}
		
	# Put in the values label
	if (defined $self->{"values_label"}) {
		my $offset = $canvasb - int ( ($canvasheight-($self->{"values_label_font"}->{"w"}*length($self->{"values_label"}))) /2);
		$img->stringUp($fonts{$self->{"values_label_font"}}
		              ,$self->{"left_gutter"}+$self->{"values_label_padding"}
					  ,$offset
					  ,"$self->{values_label}"
					  ,$colors{$self->{"values_label_font_color"}}
					  );
		}

	# Put in the Title
	if ( defined $self->{"title"} ) {
		my $offset= $canvasl + (($canvaswidth - (length($self->{"title"}) * $self->{"title_font"}->{"w"}))/2);
		$img->string($fonts{$self->{"title_font"}},$offset,$self->{"top_gutter"}+$self->{"title_padding"},"$self->{title}",$colors{$self->{"title_font_color"}});
		}

	# Put in the SubTitle
	if ( defined $self->{"subtitle"} ) {
		my $offset= $canvasl + (($canvaswidth - (length($self->{"subtitle"}) * $self->{"subtitle_font"}->{"w"}))/2);
		$img->string($fonts{$self->{"subtitle_font"}}
		            ,$offset
					,$canvast - $self->{"subtitle_padding"} - $self->{"subtitle_font"}->{"h"}
					,"$self->{subtitle}"
					,$colors{$self->{"subtitle_font_color"}}
					);
		}

	# Put in values and ticks
	foreach (@value_labels) {
		next if ($_ > $self->{"value_max"});
		next if ($_ < $self->{"value_min"});
		my $offset = int ( (($_-$self->{"value_min"})/($self->{"value_max"}-$self->{"value_min"})) * $canvasheight );
		$img->line($canvasl-1-$self->{"tick_width"},$canvasb-$offset,$canvasl-1,$canvasb-$offset,$colors{$self->{"line_color"}});
		$img->string($fonts{$self->{"values_font"}}
		            ,int($canvasl -1 -$self->{"tick_width"} -$self->{"tick_padding"} 
					     -$self->{"values_padding"} 
						 -(length($self->format($_)) * $self->{"values_font"}->{"w"}))
		            ,$canvasb -$offset- ($self->{"values_font"}->{"h"} / 2)
					,$self->format($_)
					,$colors{$self->{"values_font_color"}}
					);

		}

	# Label the value of each bar?

	# Output the image!
	if ($filename) {
		open(FILE,">$filename");
		binmode(FILE);
                print FILE  $img->png;
		close(FILE);
		}
	else {
                print $img->png;
		}
		
} # end of output

1;
__END__

ouch, my brain needs a rest after that :)
