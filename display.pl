#!/usr/bin/perl
# vim:ts=4:shiftwidth=4:expandtab:smartindent

use strict;
use warnings;

use SDL;
use SDL::Video;
use SDLx::App;
use SDL::Surface;
use SDL::Rect;
use SDL::Image;
use JSON::XS qw/ decode_json /;
use POSIX ":sys_wait_h";
use Time::HiRes qw/ sleep /;

pipe(my $command_r, my $command_w) or die $!;
pipe(my $resp_r, my $resp_w)       or die $!;


my $pid = fork() // die $!;
if (!$pid) {
    close $command_r;
    close $resp_w;

    open(STDOUT, ">&", $command_w) or die $!;
    open(STDIN,  "<&", $resp_r)    or die $!;
    exec("./tron") or die $!;
}

close $command_w;
close $resp_r;

my $app = SDLx::App->new(
    title  => "Pretend GraphWin",
    width  => 800,
    height => 600,
    depth  => 32,
);

my $bg = SDL::Rect->new(0, 0, 800, 600);
SDL::Video::fill_rect(
    $app,
    $bg,
    SDL::Video::map_RGB($app->format, 255, 255, 255),
);

my @objects;

while (my $line = <$command_r>) {
    chomp $line;
    my $query = decode_json($line);
 
    plot_obj($query);
 
    SDL::Video::update_rects($app, $bg);
}

waitpid($pid, 0) or die $!;


sub plot_obj {
    my ($obj) = @_;
    if ($obj->{action} eq 'init') {
        return;
    }
    elsif ($obj->{action} eq 'drawoblong') {
        SDL::GFX::Primitives::box_RGBA(
            $app,
            $obj->{x2},
            $obj->{y2},
            $obj->{x1},
            $obj->{y1},
            $obj->{brushr},
            $obj->{brushg},
            $obj->{brushb},
            255,
        );
        SDL::GFX::Primitives::rectangle_RGBA(
            $app,
            $obj->{x2},
            $obj->{y2},
            $obj->{x1},
            $obj->{y1},
            $obj->{penr},
            $obj->{peng},
            $obj->{penb},
            255,
        );
    }
    else {
        die "unimplemented ".$obj->{action};
    }
    return;
}
