#!/usr/bin/perl -w
package VircadiaBuilder::Template;

use strict;
use Exporter;
our (@EXPORT, @ISA);



BEGIN {
	@ISA = qw(Exporter);
	@EXPORT = qw( );
}

=pod

=head1 NAME

VircadiaBuilder::Template - Templating system

=head1 DESCRIPTION

Simple templating system for generating files with templated contents

=head1 FUNCTIONS

=cut



sub new {
    my ($class, $base_path) = @_;
    my $self = {};
    bless $self, $class;

    $self->{base_path} = $base_path;
    $self->{values} = {};

    $self->fork_name("Overte");
    return $self;
}

=item fork_id($value)

Get/set identifier of the fork. Single word, used for directory names.

Eg, "Overte"

=cut

sub fork_id {
    my ($self, $val) = @_;

    if (defined $val) {
        $self->{fork} = $val;
    }

    return $self->_getset('fork_id', $val);
}


=item fork_name($value)

Get/set name of the fork. Can be multiple words.

Eg, "Overte"

=cut

sub fork_name {
    my ($self, $val) = @_;
    return $self->_getset('fork_name', $val);
}


=item version($value)

Get/set the version

Eg, 1.0

=cut

sub version {
    my ($self, $val) = @_;
    return $self->_getset('version', $val);
}


=item write_appstream($destination, %values)

Writes the AppStream XML to the $destination directory.

Returns the full path to the generated file.

The right filename depends on the fork being used, so this function
will generate and return the right filename when called.

=cut

sub write_appstream {
    my ($self, $destination, %values) = @_;

    my $dest_filename;

    if ( $self->{fork} eq "Overte" ) {
        $dest_filename = "$destination/org.overte.interface.appdata.xml";
    } elsif ( $self->{fork} eq "Vircadia" ) {
        $dest_filename = "$destination/Vircadia.appdata.xml";
    } elsif ( $self->{fork} eq "Tivoli" ) {
        $dest_filename = "$destination/Tivoli.appdata.xml";
    } else {
        die "Unknown fork: $self->{fork}";
    }

    $self->_deploy("appstream.xml", $dest_filename, %values);

    return $dest_filename;
}

sub write_appimage_desktop_file {
    my ($self, $destination, %values) = @_;

    my $dest_filename;

    if ( $self->{fork} eq "Overte" ) {
        $dest_filename = "$destination/org.overte.interface.desktop";
    } elsif ( $self->{fork} eq "Vircadia" ) {
        $dest_filename = "$destination/com.vircadia.interface.desktop";
    } elsif ( $self->{fork} eq "Tivoli" ) {
        $dest_filename = "$destination/com.tivolivr.interface.desktop";
    } else {
        die "Unknown fork: '" . $self->{fork} . "'";
    }

    $self->_deploy("appimage.desktop", $dest_filename, %values);

    return $dest_filename;

}


sub _deploy {
    my ($self, $source_file, $destination, %values) = @_;

    local $/;
    undef $/;

    my $file_path = $self->{base_path} . "/templates/" . $self->fork_name . "/${source_file}";
    my $data;

    open(my $fh, '<',  $file_path) or die "Failed to read '$file_path': $!";
    $data = <$fh>;
    close $fh;

    # Process the passed values first, these take priority
    foreach my $k (keys %values) {
        my $v = $values{$k};
        $data =~ s/\$${k}/$v/g;
    }

    # Then the internally stored key/values
    foreach my $k (keys %{$self->{values}} ) {
        my $v = $self->{values}->{$k};
        $data =~ s/\$${k}/$v/g;
    }


    open(my $out, '>', $destination) or die "Failed to write to '$destination': $!";
    print $out $data;
    close $out;
}

sub _getset {
    my ($self, $key, $value) = @_;
    my $cur = $self->{values}->{$key};

    if (defined $value) {
        $self->{values}->{$key} = $value;
    }

    return $cur;
}

1;