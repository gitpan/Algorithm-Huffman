package Algorithm::Huffman;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Nothing to export here

our $VERSION = '0.02';

use Heap::Fibonacci;
use Tree::DAG_Node;

sub new {
    my ($proto, $count_hash) = @_;
    my $class = ref($proto) || $proto;
    
    my $heap = Heap::Fibonacci->new;
    
    my $size = 0;
    while (my ($str, $count) = each %$count_hash) {
        my $leaf = Tree::DAG_Node->new({name => $str});
        $leaf->attribute->{bit} = "";
        $heap->add( KeyValuePair->new( $leaf, $count ) );
        $size++;
    }
    
    while ($size-- >= 2) {        
        my $right = $heap->extract_minimum;
        my $left  = $heap->extract_minimum;
        $right->key->attribute->{bit} = 1;
        $left->key->attribute->{bit}  = 0;
        my $new_node = Tree::DAG_Node->new({daughters => [$left->key, $right->key]});
        $new_node->attribute->{bit} = "";
        my $new_count = $left->value + $right->value;
        $heap->add( KeyValuePair->new( $new_node, $new_count ) );
    }
    
    my $root = $heap->extract_minimum->key;
    
    my %encode;
    my %decode;
    foreach my $leaf ($root->leaves_under) {
        my @bit = reverse map {$_->attribute->{bit}} ($leaf, $leaf->ancestors);
        my $bitstr = join "", @bit;
        $encode{$leaf->name} = $bitstr;
        $decode{$bitstr}     = $leaf->name;
    }
    
    my $self = {
        encode => \%encode,
        decode => \%decode
    };
    
    bless $self, $class;
}

sub encode_hash {
    my $self = shift;
    $self->{encode};
}

sub decode_hash {
    my $self = shift;
    $self->{decode};
}

1;

package KeyValuePair;

use Heap::Elem;

require Exporter;

our @ISA = qw/Exporter Heap::Elem/;

sub new {
   my ($proto, $key, $value) = @_;
   my $class = ref($proto) || $proto;

   my $self = $class->SUPER::new;

   $self->{"KeyValuePair::key"}   = $key;
   $self->{"KeyValuePair::value"} = $value;
   
   return $self;
}

sub cmp {
   my ($self, $other) = @_;
   $self->{"KeyValuePair::value"} <=> $other->{"KeyValuePair::value"};
}

sub key {
    my $self = shift;
    return $self->{"KeyValuePair::key"};
}

sub value {
    my $self = shift;
    return $self->{"KeyValuePair::value"};
}

1;


__END__

=head1 NAME

Algorithm::Huffman - Perl extension that implements the Huffman algorithm

=head1 SYNOPSIS

  use Algorithm::Huffman;

  my $huff = Algorithm::Huffman->new(\%char_counting);
  my $encode_hash = $huff->encode_hash;
  my $decode_hash = $huff->decode_hash;

=head1 DESCRIPTION

This modules implements the huffman algorithm.
The aim is to create a good coding scheme for a given list
of different characters (or even strings) and their occurence numbers.

=head2 ALGORITHM

Please have a look to a good data compression book for a detailed view.
However, the algorithm is like every good algorithm very easy.

Assume we have a heap (keys are the characters/strings; 
values are their occurencies). In each step of the algorithm, 
the two rarest characters are looked at. 
Both get a suffix (one "0", the other "1").
They are joined together and will occur from that time as one "element"
in the heap with their summed occurencies.
The joining creates a tree growing on while the heap is reducing.

Let's take an example. Given are the characters and occurencies.

  a (15) b(7) c(6) d(6) e(5)
  
In the first step e and d are the rarest characters,
so we create this new heap and tree structure:

  a(15) de(11) b(7) c(6)
  
        de
       /  \
   "0"/    \"1"
     d      e
     
Next Step:

  a(15) bc(13) de(11)
  
        de                bc
       /  \              /  \
   "0"/    \"1"      "0"/    \"1"
     d      e          b      c
     
Next Step:

  a(15) bcde(24)
  
                bcde
              /      \
         "0"/          \"1"
          /              \
        de                bc
       /  \              /  \
   "0"/    \"1"      "0"/    \"1"
     d      e          b      c
                      
Next Step unifies the rest:
 
                             Huffman-Table
                                /    \
                          "0"/          \"1"
                         /                  \
                     /                          \
                bcde                              a
              /      \
         "0"/          \"1"
          /              \
        de                bc
       /  \              /  \
   "0"/    \"1"      "0"/    \"1"
     d      e          b      c
     

Finally this encoding table would be created:

   a    1
   b    010
   c    011
   d    000
   e    001

Please note, that there is no rule defining what element in the tree
is ordered to left or to right. So it's also possible to get e.g. the coding
scheme:

   a    0
   b    100
   c    101
   d    110
   e    111

=head2 METHODS

=over

=item my $huff = Algorithm::Huffman->new( HASHREF )

Creates a new Huffman table,
based on the given occurencies of characters.
The keys of the given hashref are the characters/strings,
the values are their occurencies.

A hashref is used, as such a hash can become quite large
(e.g. all three letter combinations).

=item $huff->encode_hash

Returns a reference to the encoding hash.
The keys of the encoding hash are the characters/strings passed
at the construction. The values are their bit representation.
Please note that the bit represantations are strings 
of ones and zeros is returned and not binary numbers.

=item $huff->decode_hash

Returns a reference to the decoding hash.
The keys of the decoding hash are the bit presentations,
while the values are the characters/strings the bitstrings stands for.
Please note that the bit represantations are strings 
of ones and zeros is returned and not binary numbers.

=back   

=head2 EXPORT

None by default.

=head1 BUGS

There is no great parameter validation.
That will be changed in future versions.

If a character/string has occurs zero times, it is still coded.
At the moment, you have to grep them out before.
I don't plan to change it,
as it can realistic happen and they would play a role.
(Imagine, you would code all three letter combinations found in some
english texts, you still would have to code all ASCII characters,
even if they don't occur in the texts you have analyzed.
Reason is that they could occur in other texts and
you would have to guarantee that you can code every text
without any lost information)

It isn't tested with a big histogram of characters/strings.

There could be some others,
as this code is still in the ALPHA stadium.

=head1 TODO

I'll need a C<encode> and C<decode> method
based on the created internal huffman table should be implemented.

=head1 SEE ALSO

Every good book about data compression.

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Janek Schleicher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
