#!/usr/bin/perl -w

use strict;

use Test::More tests => 18;

use XML::SAX::ParserFactory;

use t::MockXMLSAXConsumer;

package t::XMLFilterTest;

use base qw( XML::Filter::Conditional );

sub store_switch
{
   return undef;
}

sub eval_case
{
   return 0;
}

package main;

# Set up the XML object chain

my $out = t::MockXMLSAXConsumer->new();
my $filter = t::XMLFilterTest->new( Handler => $out );
my $parser = XML::SAX::ParserFactory->parser( Handler => $filter );

$parser->parse_string( <<EOXML );
<data>
  Here is some character data
  <node attr="value" />
  <!-- A comment here -->
  <?process obj="self"?>
</data>
EOXML

my @methods;

@methods = $out->GET_LOG;

my $m;

# ->start_element ( { Name => 'data', ... } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'data' );
is_deeply( $m->[1]{Attributes}, {} );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n  Here is some character data\n  " } ] );

# ->start_element ( { Name => 'node' with attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'node' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}attr' ] );
is( $m->[1]{Attributes}{'{}attr'}{Value}, 'value' );

# ->end_element ( { Name => 'node', ... } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'node' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n  " } ] );

# ->comment
$m = shift @methods;
is_deeply( $m, [ 'comment', { Data => " A comment here " } ] );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n  " } ] );

# ->processing_instruction
$m = shift @methods;
is_deeply( $m, [ 'processing_instruction', { Target => 'process', Data => 'obj="self"' } ] );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n" } ] );

# ->end_element ( { Name => 'data', ... } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'data' );

is( scalar @methods, 0 );
