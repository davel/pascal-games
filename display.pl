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
use SDL::Joystick;
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

#SDL::init_sub_system(SDL_INIT_JOYSTICK);

#my @joystick = (SDL::Joystick->new(0));

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

my $text_y = 0;
my $text_height = 20;

while (my $line = <$command_r>) {
    chomp $line;
    my $query = decode_json($line);

    SDL::Joystick::update();

    if ($query->{action} eq 'init') {
        next;
    }
    elsif ($query->{action} eq 'writeln') {
        my %str = (
            action  => 'drawtext',
            x       => 0,
            y       => $text_y,
            penr    => 0,
            peng    => 0,
            penb    => 0,
            string  => $query->{string},
        );
        plot_obj(\%str);
        SDL::Video::update_rects($app, $bg);
        push @objects, \%str;
        $text_y += $text_height;
    }
    elsif ($query->{action} eq 'drawtext') {
        plot_obj($query);
        SDL::Video::update_rects($app, $bg);
        push @objects, $query;
    }
    elsif ($query->{action} eq 'drawoblong') {
        plot_obj($query);
        SDL::Video::update_rects($app, $bg);
        push @objects, $query;
    }
    elsif ($query->{action} eq 'eraseoblong' || $query->{action} eq 'erasetext') {
        my $s = $query->{action};
        $s =~ s/erase/draw/;
        my $erase;
        COMP: for my $i (0..scalar(@objects)-1) {
            next COMP if $s ne $objects[$i]->{action};
            for my $h (qw/ x1 x2 y1 y2 x y string penr peng penb brushr brushg brushb style /) {
                next if !defined($query->{$h}) && !defined($objects[$i]->{$h});
                next COMP if $query->{$h} ne $objects[$i]->{$h};
            }
            splice(@objects, $i, 1);
            $erase = 1;
            last;
        }
        if (!$erase) {
            die "could not erase $line";
        }
        refresh();
    }
    elsif ($query->{action} eq 'keypressed') {
        syswrite($resp_w, "0\n") or die $!;
    }
    else {
    }
 
    #sleep 0.01;
}

sleep 2;

waitpid($pid, 0) or die $!;


sub plot_obj {
    my ($obj) = @_;
    if ($obj->{action} eq 'drawoblong') {
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
    elsif ($obj->{action} eq 'drawtext') {
        SDL::GFX::Primitives::string_RGBA(
            $app,
            $obj->{x},
            $obj->{y},
            $obj->{string},
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

sub refresh {
    my $bg = SDL::Rect->new(0, 0, 800, 600);
    SDL::Video::fill_rect(
        $app,
        $bg,
        SDL::Video::map_RGB($app->format, 255, 255, 255),
    );

    for my $obj (@objects) {
        plot_obj($obj);
    }

    SDL::Video::update_rects($app, $bg);

    return;
}
