use v5.14;
use warnings;

=head1 NAME

AtteanX::Parser::SPARQLTSV - SPARQL Results TSV Parser

=head1 VERSION

This document describes AtteanX::Parser::SPARQLTSV version 0.001

=head1 SYNOPSIS

 use Attean;

=head1 DESCRIPTION

...

=head1 METHODS

=over 4

=cut

package AtteanX::Parser::SPARQLTSV 0.001 {
	use utf8;
	use Moo;
	use Attean;
	use Encode qw(decode);
	use List::MoreUtils qw(zip);
	use namespace::clean;

	sub canonical_media_type { return "text/tab-separated-values" }

	sub media_types {
		return [qw(text/tab-separated-values)];
	}
	
	with 'Attean::API::ResultParser', 'Attean::API::PullParser', 'Attean::API::Parser';

=item C<< parse_iter_from_bytes( $data ) >>

Returns an iterator of L<Attean::API::Binding> objects that result from parsing
the data read from the UTF-8 encoded byte string C<< $data >>.

=cut

	sub parse_iter_from_bytes {
		my $self	= shift;
		my $data	= shift;
	
		$data	= Encode::encode("utf-8", $data);
		open(my $fh, '<:encoding(UTF-8)', \$data);
		return $self->parse_iter_from_io($fh);
	}

=item C<< parse_iter_from_io( $fh ) >>

Returns an iterator of L<Attean::API::Binding> objects that result from parsing
the data read from the L<IO::Handle> object C<< $fh >>.

=cut

	sub parse_iter_from_io {
		my $self	= shift;
		my $fh		= shift;
		
		my $line	= <$fh>;
		chomp($line);
		my @vars;
		my $parser	= Attean->get_parser('Turtle')->new();
		foreach my $v (split("\t", $line)) {
			die "Bad variable syntaxin SPARQL TSV data: '$v'" unless (substr($v, 0, 1) eq '?');
			push(@vars, substr($v, 1));
		}
		
		my $gen		= sub {
			my $line	= <$fh>;
			return unless defined($line);
			chomp($line);
			my @strings	= split("\t", $line);
			my %binding;
			foreach my $i (0 .. $#vars) {
				my $string	= $strings[$i];
				if (length($string)) {
					my $var	= $vars[$i];
					my $term	= $parser->parse_term_from_string($string);
					if ($term) {
						$binding{ $var }	= $term;
					}
				}
			}
			return Attean::Result->new( bindings => \%binding );
		};
		return Attean::CodeIterator->new(
			generator => $gen,
			item_type => $self->handled_type,
		);
	}

}

1;

__END__

=back

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/kasei/perlrdf/issues>.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2006-2012 Gregory Todd Williams. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut