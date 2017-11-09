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
use SDL::Event;
use SDL::Events;
use JSON::XS qw/ decode_json /;
use POSIX ":sys_wait_h";
use Time::HiRes qw/ sleep gettimeofday tv_interval /;
use List::Util qw/ max /;

my $game = $ARGV[0];

SDL::init_sub_system(SDL_INIT_JOYSTICK);
SDL::init_sub_system(SDL_INIT_VIDEO);

my $event = SDL::Event->new();

my $key;

my $num_joysticks = SDL::Joystick::num_joysticks();
if ($num_joysticks > 3) {
    $num_joysticks = 3;
}

my @keymap = (
    {
        "u" => 'q',
        "d" => 'a',
        "l" => 'z',
        "r" => 'x',
    },
    {
        u   => '8',
        d   => '2',
        l   => '4',
        r   => '6',
    },
    {
        u   => 'k',
        d   => 'b',
        l   => 'j',
        r   => 'l',
    },
);

my $app = SDLx::App->new(
    title  => "Pretend GraphWin",
    width  => 800,
    height => 600,
    depth  => 32,
);
# $app->fullscreen;

my @joystick = (map { SDL::Joystick->new($_) } 0..$num_joysticks );
printf("Name: %s\n",              SDL::Joystick::name(1));
printf("Number of Axes: %d\n",    SDL::Joystick::num_axes($joystick[1]));


my @button_time;
my @button;

my $pid;
my $exit;

$SIG{INT} = sub {
    kill(15, $pid) if $pid;
    $exit = 1;
};

my @objects;

while (!$exit) {
    my $bg = SDL::Rect->new(0, 0, 800, 600);
    SDL::Video::fill_rect(
        $app,
        $bg,
        SDL::Video::map_RGB($app->format, 255, 255, 255),
    );

    @objects = ();
    my $text_y = 0;
    my $text_height = 20;

    pipe(my $command_r, my $command_w) or die $!;
    pipe(my $resp_r, my $resp_w)       or die $!;

    my $pid = fork() // die $!;
    if (!$pid) {
        close $command_r;
        close $resp_w;

        open(STDOUT, ">&", $command_w) or die $!;
        open(STDIN,  "<&", $resp_r)    or die $!;
        exec($ARGV[0]) or die $!;
    }

    close $command_w;
    close $resp_r;


    while (my $line = <$command_r>) {
        chomp $line;
        my $query = decode_json($line);

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
            push @objects, $query;
        }
        elsif ($query->{action} eq 'drawoblong') {
            plot_obj($query);
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
            $key ||= joystick();
             syswrite($resp_w, $key ? "1\n":"0\n") or die $!;
        }
        elsif ($query->{action} eq 'readkey') {
            syswrite($resp_w, "$key\n") or die $!;
            $key = "";
        }
        elsif ($query->{action} eq 'sleep') {
            my $t0 = [gettimeofday];
            SDL::Video::update_rects($app, $bg);

            sleep(max($query->{duration}-tv_interval($t0), 0));
            syswrite($resp_w, "x\n") or die $!;
        }


        else {
            die "No action! ".$query->{action};
        }
        
        SDL::Events::pump_events();

        if (SDL::Events::poll_event($event)) {
            if ($event->type == SDL_KEYDOWN) {
                kill(15, $pid);
                $exit = 1;
            }
        }

     
        #sleep 0.01;
    }

    sleep 2;

    waitpid($pid, 0) or die $!;
    $pid = undef;
}

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

    return;
}

sub joystick {
    SDL::Joystick::update();
    for (my $i=0; $i<$num_joysticks; $i++) {
        $button[$i] ||= "";
        $button_time[$i] ||= [gettimeofday];

        my $dir = "";

        if (SDL::Joystick::num_axes($joystick[$i]) == 27) {
            $dir = 'u' if SDL::Joystick::get_button($joystick[$i], 4); 
            $dir = 'd' if SDL::Joystick::get_button($joystick[$i], 6);
            $dir = 'l' if SDL::Joystick::get_button($joystick[$i], 7);
            $dir = 'r' if SDL::Joystick::get_button($joystick[$i], 5);
        }
        elsif (SDL::Joystick::num_axes($joystick[$i]) == 4) {
            $dir = 'u' if SDL::Joystick::get_axis($joystick[$i], 1) < 0; 
            $dir = 'd' if SDL::Joystick::get_axis($joystick[$i], 1) > 0;
            $dir = 'l' if SDL::Joystick::get_axis($joystick[$i], 0) < 0;
            $dir = 'r' if SDL::Joystick::get_axis($joystick[$i], 0) > 0;
        }
        print "xx $i $dir\n";
        if ($dir ne $button[$i] || tv_interval($button_time[$i]) > 0.2 ) {
            $button[$i] = $dir;
            $button_time[$i] = [gettimeofday];
            return $keymap[$i]->{$dir} if $dir ne "";
        }
    }
    return;
}
