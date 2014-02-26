package Term::Choose::Win32;

use 5.10.1;
use warnings;
use strict;

our $VERSION = '0.022';
use Exporter 'import';
our @EXPORT_OK = qw(choose);

use Carp qw(croak carp);
use Term::Choose;
use Term::Size::Win32 qw(chars);
use Unicode::GCString;
use Win32::Console qw(
    STD_INPUT_HANDLE ENABLE_MOUSE_INPUT
    RIGHT_ALT_PRESSED LEFT_ALT_PRESSED RIGHT_CTRL_PRESSED LEFT_CTRL_PRESSED SHIFT_PRESSED
);
use Win32::Console::ANSI qw(:func);
# print "\e(U";      # fails the 00-load test
INIT{ print "\e(U" } # workaround

no warnings 'utf8';
#use warnings FATAL => qw(all);
#use Log::Log4perl qw(get_logger);
#my $log = get_logger( 'Term::Choose::Win32' );

use constant {
    ROW     => 0,
    COL     => 1,
    MIN     => 0,
    MAX     => 1,
};

use constant {
    UP                              => "\e[A",
    NL                              => "\n",
    RIGHT                           => "\e[C",
    LEFT                            => "\e[D",

    HIDE_CURSOR                     => "\e[?25l",
    SHOW_CURSOR                     => "\e[?25h",

    MAX_ROW_MOUSE_1003              => 223,
    MAX_COL_MOUSE_1003              => 223,

    BEEP                            => "\07",
    CLEAR_TO_END_OF_SCREEN          => "\e[0J",
    RESET                           => "\e[0m",
    UNDERLINE                       => "\e[4m",
    REVERSE                         => "\e[7m",
    BOLD                            => "\e[1m",
};

use constant {
    NEXT_get_key      => -1,

    CONTROL_SPACE   => 0x00,
    CONTROL_A       => 0x01,
    CONTROL_B       => 0x02,
    CONTROL_C       => 0x03,
    CONTROL_D       => 0x04,
    CONTROL_E       => 0x05,
    CONTROL_F       => 0x06,
    CONTROL_H       => 0x08,
    KEY_BTAB        => 0x08,
    CONTROL_I       => 0x09,
    KEY_TAB         => 0x09,
    KEY_ENTER       => 0x0d,
    KEY_ESC         => 0x1b,
    KEY_SPACE       => 0x20,
    KEY_h           => 0x68,
    KEY_j           => 0x6a,
    KEY_k           => 0x6b,
    KEY_l           => 0x6c,
    KEY_q           => 0x71,
    KEY_Tilde       => 0x7e,
    KEY_BSPACE      => 0x7f,

    KEY_UP          => 0x1b5b41,
    KEY_DOWN        => 0x1b5b42,
    KEY_RIGHT       => 0x1b5b43,
    KEY_LEFT        => 0x1b5b44,
    KEY_PAGE_UP     => 0x1b5b35,
    KEY_PAGE_DOWN   => 0x1b5b36,
    KEY_HOME        => 0x1b5b48,
    KEY_END         => 0x1b5b46,
    KEY_INSERT      => 0x1b5b32,
    KEY_DELETE      => 0x1b5b33,
};

use constant {
    MOUSE_WHEELED                => 0x0004,

    LEFTMOST_BUTTON_PRESSED      => 0x0001,
    RIGHTMOST_BUTTON_PRESSED     => 0x0002,
    FROM_LEFT_2ND_BUTTON_PRESSED => 0x0004,
};

use constant {
    VK_PAGE_UP   => 33,
    VK_PAGE_DOWN => 34,
    VK_END       => 35,
    VK_HOME      => 36,
    VK_LEFT      => 37,
    VK_UP        => 38,
    VK_RIGHT     => 39,
    VK_DOWN      => 40,
    VK_INSERT    => 45,
    VK_DELETE    => 46,
};

use constant SHIFTED_MASK =>
    RIGHT_ALT_PRESSED |
    LEFT_ALT_PRESSED |
    RIGHT_CTRL_PRESSED |
    LEFT_CTRL_PRESSED |
    SHIFT_PRESSED;


sub _get_key {
    my ( $arg ) = @_;
    my @event = $arg->{input}->Input;
    my $event_type = shift @event;
    return NEXT_get_key if ! defined $event_type;
    if ( $event_type == 1 ) {
        my ( $key_down, $repeat_count, $v_key_code, $v_scan_code, $char, $ctrl_key_state ) = @event;
        return NEXT_get_key if ! $key_down;
        if ( $char ) {
            if ( $char == 32 && $ctrl_key_state & ( RIGHT_CTRL_PRESSED | LEFT_CTRL_PRESSED ) ) {
                return CONTROL_SPACE;
            }
            else {
                return $char;
            }
        }
        else{
            if ( $ctrl_key_state & SHIFTED_MASK ) {
                return NEXT_get_key;
            }
            elsif ( $v_key_code == VK_PAGE_UP )   { return KEY_PAGE_UP }
            elsif ( $v_key_code == VK_PAGE_DOWN ) { return KEY_PAGE_DOWN }
            elsif ( $v_key_code == VK_END )       { return KEY_END }
            elsif ( $v_key_code == VK_HOME )      { return KEY_HOME }
            elsif ( $v_key_code == VK_LEFT )      { return KEY_LEFT }
            elsif ( $v_key_code == VK_UP )        { return KEY_UP }
            elsif ( $v_key_code == VK_RIGHT )     { return KEY_RIGHT }
            elsif ( $v_key_code == VK_DOWN )      { return KEY_DOWN }
            elsif ( $v_key_code == VK_INSERT )    { return KEY_INSERT }
            elsif ( $v_key_code == VK_DELETE )    { return KEY_DELETE }
            else                                  { return NEXT_get_key }
        }
    }
    elsif ( $arg->{mouse} && $event_type == 2 ) {
        my( $x, $y, $button_state, $control_key, $event_flags ) = @event;
        my $compat_event_type;
        if ( ! $event_flags ) {
            if ( $button_state & LEFTMOST_BUTTON_PRESSED ) {
                $compat_event_type = 0b0000000; # 1
            }
            elsif ( $button_state & RIGHTMOST_BUTTON_PRESSED ) {
                $compat_event_type = 0b0000010; # 3
            }
            elsif ( $button_state & FROM_LEFT_2ND_BUTTON_PRESSED ) {
                $compat_event_type = 0b0000001; # 2
            }
            else {
                return NEXT_get_key;
            }
        }
        elsif ( $event_flags & MOUSE_WHEELED ) {
            if ( $button_state >> 24 ) {
                $compat_event_type = 0b1000001; # 5
            }
            else {
                $compat_event_type = 0b1000000; # 4
            }
        }
        else {
            return NEXT_get_key;
        }
        return _handle_mouse( $arg, $compat_event_type, $x, $y );
    }
    else {
        return NEXT_get_key;
    }
}


sub _init_scr {
    # OO so DESTROY does the cleanup.
    my $class = shift;
    my ( $arg ) = @_;
    my $self = bless $arg, $class;
    $self->{old_handle} = select( $self->{handle_out} );
    $self->{backup_flush} = $|;
    $| = 1;
    $self->{input} = Win32::Console->new( STD_INPUT_HANDLE );
    $self->{old_in_mode} = $arg->{input}->Mode();
    $self->{input}->Mode( ENABLE_MOUSE_INPUT ) if $self->{mouse};
    print HIDE_CURSOR if $self->{hide_cursor};
    return $self;
}

sub DESTROY {
    my $self = shift;
    print LEFT x $self->{screen_col}, UP x ( $self->{screen_row} + $self->{nr_prompt_lines} );
    print CLEAR_TO_END_OF_SCREEN;
    print RESET;
    $self->{input}->Mode( $self->{old_in_mode} ) if $self->{mouse};
    $self->{input}->Flush;
    # workaround Bug #33513:
    $self->{input}{handle} = undef;
    #
    print SHOW_CURSOR if $self->{hide_cursor};
    $| = $self->{backup_flush};
    select( $self->{old_handle} );
    carp "EOT: $!"      if $self->{EOT};
    print STDERR "^C\n" if $self->{cC};
}


sub _get_term_size {
    my ( $fh ) = @_;
    my ( $term_width, $term_height ) = chars( $fh );
    return $term_width - 1, $term_height;
}


sub _write_first_screen {
    my ( $arg ) = @_;
    ( $arg->{term_width}, $arg->{term_height} ) = _get_term_size( $arg->{handle_out} );
    ( $arg->{avail_width}, $arg->{avail_height} ) = ( $arg->{term_width}, $arg->{term_height} );
    if ( $arg->{max_width} && $arg->{avail_width} > $arg->{max_width} ) {
        $arg->{avail_width} = $arg->{max_width};
    }
    if ( $arg->{mouse} == 2 ) {
        $arg->{avail_width}  = MAX_COL_MOUSE_1003 if $arg->{avail_width}  > MAX_COL_MOUSE_1003;
        $arg->{avail_height} = MAX_ROW_MOUSE_1003 if $arg->{avail_height} > MAX_ROW_MOUSE_1003;
    }
    $arg->{avail_width} = 1 if $arg->{avail_width} < 1;
    if ( $arg->{prompt} eq '' ) {
        $arg->{nr_prompt_lines} = 0;
    }
    else {
        Term::Choose::_prepare_promptline( $arg );
    }
    $arg->{tail} = $arg->{page} ? 1 : 0;
    $arg->{avail_height} -= $arg->{nr_prompt_lines} + $arg->{tail};
    if ( $arg->{avail_height} < $arg->{keep} ) {
        my $height = ( _get_term_size( $arg->{handle_out} ) )[1];
        $arg->{avail_height} = $height >= $arg->{keep} ? $arg->{keep} : $height;
        $arg->{avail_height} = 1 if $arg->{avail_height} < 1;
    }
    $arg->{avail_height} = $arg->{max_height} if $arg->{max_height} && $arg->{max_height} < $arg->{avail_height};
    Term::Choose::_size_and_layout( $arg );
    Term::Choose::_prepare_page_number( $arg ) if $arg->{page};
    $arg->{avail_height_idx} = $arg->{avail_height} - 1;
    $arg->{p_begin}    = 0;
    $arg->{p_end}      = $arg->{avail_height_idx};
    $arg->{p_end}      = $#{$arg->{rc2idx}} if $arg->{avail_height_idx} > $#{$arg->{rc2idx}};
    $arg->{marked}     = [];
    $arg->{row_on_top} = 0;
    $arg->{screen_row} = 0;
    $arg->{screen_col} = 0;
    $arg->{cursor}     = [ 0, 0 ];
    Term::Choose::_set_default_cell( $arg ) if defined $arg->{default} && $arg->{default} <= $#{$arg->{list}};
    if ( $arg->{clear_screen} ) {
        print NL x $arg->{term_height};
        print UP x $arg->{term_height};
    }
    print $arg->{prompt_copy} if $arg->{prompt} ne '';
    _wr_screen( $arg );
    if ( $arg->{mouse} ) {
        ( $arg->{abs_cursor_x}, $arg->{abs_cursor_y} ) = Cursor();
        #$arg->{abs_cursor_x}--;
        $arg->{abs_cursor_y}--;
        $arg->{cursor_row} = $arg->{screen_row};
    }
}


sub choose {
    my ( $orig_list_ref, $config ) = @_;
    croak "choose: called without arguments. 'choose' expects 1 or 2 arguments." if @_ < 1;
    croak "choose: called with " . scalar @_ . " arguments. 'choose' expects 1 or 2 arguments." if @_ > 2;
    croak "choose: The first argument is not defined. "
        . "The first argument has to be an ARRAY reference." if ! defined $orig_list_ref;
    croak "choose: The first argument is not a reference. "
        . "The first argument has to be an ARRAY reference." if ref( $orig_list_ref ) eq '';
    croak "choose: The first argument is not an ARRAY reference. "
        . "The first argument has to be an ARRAY reference." if ref( $orig_list_ref ) ne 'ARRAY';
    if ( defined $config ) {
        croak "choose: The second argument is not a reference. "
            . "The (optional) second argument has to be a HASH reference." if ref( $config ) eq '';
        croak "choose: The second argument is not a HASH reference. "
            . "The (optional) second argument has to be a HASH reference." if ref( $config ) ne 'HASH';
    }
    if ( ! @$orig_list_ref ) {
        carp "choose: The first argument refers to an empty list!";
        return;
    }
    local $\ = undef;
    local $, = undef;
    my $arg = Term::Choose::_validate_options( $config // {}, wantarray, scalar @$orig_list_ref );
    $arg->{orig_list}  = $orig_list_ref;
    $arg->{handle_out} = -t \*STDOUT ? \*STDOUT : \*STDERR;
    $arg->{list}       = Term::Choose::_copy_orig_list( $arg );
    Term::Choose::_length_longest( $arg );
    $arg->{col_width} = $arg->{length_longest} + $arg->{pad};
    local $SIG{'INT'} = sub {
        my $signame = shift;
        exit( 1 );
    };
    my $init = Term::Choose::Win32->_init_scr( $arg );
    _write_first_screen( $arg );

    while ( 1 ) {
        my $key = _get_key( $arg );
        if ( ! defined $key ) {
            $arg->{EOT} = 1;
            return;
        }
        my ( $new_width, $new_height ) = _get_term_size( $arg->{handle_out} );
        if ( $new_width != $arg->{term_width} || $new_height != $arg->{term_height} ) {
            $arg->{list} = Term::Choose::_copy_orig_list( $arg );
            print LEFT x $arg->{screen_col}, UP x ( $arg->{screen_row} + $arg->{nr_prompt_lines} );
            print CLEAR_TO_END_OF_SCREEN;
            _write_first_screen( $arg );
            next;
        }
        next if $key == NEXT_get_key;
        next if $key == KEY_Tilde;

        # $arg->{rc2idx} holds the new list (AoA) formated in "_size_and_layout" appropirate to the choosen layout.
        # $arg->{rc2idx} does not hold the values dircetly but the respective list indexes from the original list.
        # If the original list would be ( 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' ) and the new formated list should be
        #     a d g
        #     b e h
        #     c f
        # then the $arg->{rc2idx} would look like this
        #     0 3 6
        #     1 4 7
        #     2 5
        # So e.g. the second value in the second row of the new list would be $arg->{list}[ $arg->{rc2idx}[1][1] ].
        # On the other hand the index of the last row of the new list would be $#{$arg->{rc2idx}}
        # or the index of the last column in the first row would be $#{$arg->{rc2idx}[0]}.

        if ( $key == KEY_j || $key == KEY_DOWN ) {
            if ( $#{$arg->{rc2idx}} == 0 || ! (    $arg->{rc2idx}[$arg->{cursor}[ROW]+1]
                                                && $arg->{rc2idx}[$arg->{cursor}[ROW]+1][$arg->{cursor}[COL]] )
            ) {
                _beep( $arg );
            }
            else {
                $arg->{cursor}[ROW]++;
                if ( $arg->{cursor}[ROW] <= $arg->{p_end} ) {
                    _wr_cell( $arg, $arg->{cursor}[ROW] - 1, $arg->{cursor}[COL] );
                    _wr_cell( $arg, $arg->{cursor}[ROW],     $arg->{cursor}[COL] );
                }
                else {
                    $arg->{row_on_top} = $arg->{cursor}[ROW];
                    $arg->{p_begin} = $arg->{p_end} + 1;
                    $arg->{p_end}   = $arg->{p_end} + $arg->{avail_height};
                    $arg->{p_end}   = $#{$arg->{rc2idx}} if $arg->{p_end} > $#{$arg->{rc2idx}};
                    _wr_screen( $arg );
                }
            }
        }
        elsif ( $key == KEY_k || $key == KEY_UP ) {
            if ( $arg->{cursor}[ROW] == 0 ) {
                _beep( $arg );
            }
            else {
                $arg->{cursor}[ROW]--;
                if ( $arg->{cursor}[ROW] >= $arg->{p_begin} ) {
                    _wr_cell( $arg, $arg->{cursor}[ROW] + 1, $arg->{cursor}[COL] );
                    _wr_cell( $arg, $arg->{cursor}[ROW],     $arg->{cursor}[COL] );
                }
                else {
                    $arg->{row_on_top} = $arg->{cursor}[ROW] - ( $arg->{avail_height} - 1 );
                    $arg->{p_end}   = $arg->{p_begin} - 1;
                    $arg->{p_begin} = $arg->{p_begin} - $arg->{avail_height};
                    $arg->{p_begin} = 0 if $arg->{p_begin} < 0;
                    _wr_screen( $arg );
                }
            }
        }
        elsif ( $key == KEY_TAB || $key == CONTROL_I ) {
            if (    $arg->{cursor}[ROW] == $#{$arg->{rc2idx}}
                 && $arg->{cursor}[COL] == $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]}
            ) {
                _beep( $arg );
            }
            else {
                if ( $arg->{cursor}[COL] < $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]} ) {
                    $arg->{cursor}[COL]++;
                    _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] - 1 );
                    _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] );
                }
                else {
                    $arg->{cursor}[ROW]++;
                    if ( $arg->{cursor}[ROW] <= $arg->{p_end} ) {
                        $arg->{cursor}[COL] = 0;
                        _wr_cell( $arg, $arg->{cursor}[ROW] - 1, $#{$arg->{rc2idx}[$arg->{cursor}[ROW] - 1]} );
                        _wr_cell( $arg, $arg->{cursor}[ROW],     $arg->{cursor}[COL] );
                    }
                    else {
                        $arg->{row_on_top} = $arg->{cursor}[ROW];
                        $arg->{p_begin} = $arg->{p_end} + 1;
                        $arg->{p_end}   = $arg->{p_end} + $arg->{avail_height};
                        $arg->{p_end}   = $#{$arg->{rc2idx}} if $arg->{p_end} > $#{$arg->{rc2idx}};
                        $arg->{cursor}[COL] = 0;
                        _wr_screen( $arg );
                    }
                }
            }
        }
        elsif ( $key == KEY_BSPACE || $key == CONTROL_H || $key == KEY_BTAB ) {
            if ( $arg->{cursor}[COL] == 0 && $arg->{cursor}[ROW] == 0 ) {
                _beep( $arg );
            }
            else {
                if ( $arg->{cursor}[COL] > 0 ) {
                    $arg->{cursor}[COL]--;
                    _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] + 1 );
                    _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] );
                }
                else {
                    $arg->{cursor}[ROW]--;
                    if ( $arg->{cursor}[ROW] >= $arg->{p_begin} ) {
                        $arg->{cursor}[COL] = $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]};
                        _wr_cell( $arg, $arg->{cursor}[ROW] + 1, 0 );
                        _wr_cell( $arg, $arg->{cursor}[ROW],     $arg->{cursor}[COL] );
                    }
                    else {
                        $arg->{row_on_top} = $arg->{cursor}[ROW] - ( $arg->{avail_height} - 1 );
                        $arg->{p_end}   = $arg->{p_begin} - 1;
                        $arg->{p_begin} = $arg->{p_begin} - $arg->{avail_height};
                        $arg->{p_begin} = 0 if $arg->{p_begin} < 0;
                        $arg->{cursor}[COL] = $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]};
                        _wr_screen( $arg );
                    }
                }
            }
        }
        elsif ( $key == KEY_l || $key == KEY_RIGHT ) {
            if ( $arg->{cursor}[COL] == $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]} ) {
                _beep( $arg );
            }
            else {
                $arg->{cursor}[COL]++;
                _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] - 1 );
                _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] );
            }
        }
        elsif ( $key == KEY_h || $key == KEY_LEFT ) {
            if ( $arg->{cursor}[COL] == 0 ) {
                _beep( $arg );
            }
            else {
                $arg->{cursor}[COL]--;
                _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] + 1 );
                _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] );
            }
        }
        elsif ( $key == CONTROL_B || $key == KEY_PAGE_UP ) {
            if ( $arg->{p_begin} <= 0 ) {
                _beep( $arg );
            }
            else {
                $arg->{row_on_top} = $arg->{avail_height} * ( int( $arg->{cursor}[ROW] / $arg->{avail_height} ) - 1 );
                $arg->{cursor}[ROW] -= $arg->{avail_height};
                $arg->{p_begin} = $arg->{row_on_top};
                $arg->{p_end}   = $arg->{p_begin} + $arg->{avail_height} - 1;
                _wr_screen( $arg );
            }
        }
        elsif ( $key == CONTROL_F || $key == KEY_PAGE_DOWN ) {
            if ( $arg->{p_end} >= $#{$arg->{rc2idx}} ) {
                _beep( $arg );
            }
            else {
                $arg->{row_on_top} = $arg->{avail_height} * ( int( $arg->{cursor}[ROW] / $arg->{avail_height} ) + 1 );
                $arg->{cursor}[ROW] += $arg->{avail_height};
                if ( $arg->{cursor}[ROW] >= $#{$arg->{rc2idx}} ) {
                    if ( $#{$arg->{rc2idx}} == $arg->{row_on_top} || ! $arg->{rest} || $arg->{cursor}[COL] <= $arg->{rest} - 1 ) {
                        if ( $arg->{cursor}[ROW] != $#{$arg->{rc2idx}} ) {
                            $arg->{cursor}[ROW] = $#{$arg->{rc2idx}};
                        }
                        if ( $arg->{rest} && $arg->{cursor}[COL] > $arg->{rest} - 1 ) {
                            $arg->{cursor}[COL] = $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]};
                        }
                    }
                    else {
                        $arg->{cursor}[ROW] = $#{$arg->{rc2idx}} - 1;
                    }
                }
                $arg->{p_begin} = $arg->{row_on_top};
                $arg->{p_end}   = $arg->{p_begin} + $arg->{avail_height} - 1;
                $arg->{p_end}   = $#{$arg->{rc2idx}} if $arg->{p_end} > $#{$arg->{rc2idx}};
                _wr_screen( $arg );
            }
        }
        elsif ( $key == CONTROL_A || $key == KEY_HOME ) {
            if ( $arg->{cursor}[COL] == 0 && $arg->{cursor}[ROW] == 0 ) {
                _beep( $arg );
            }
            else {
                $arg->{row_on_top} = 0;
                $arg->{cursor}[ROW] = $arg->{row_on_top};
                $arg->{cursor}[COL] = 0;
                $arg->{p_begin} = $arg->{row_on_top};
                $arg->{p_end}   = $arg->{p_begin} + $arg->{avail_height} - 1;
                $arg->{p_end}   = $#{$arg->{rc2idx}} if $arg->{p_end} > $#{$arg->{rc2idx}};
                _wr_screen( $arg );
            }
        }
        elsif ( $key == CONTROL_E || $key == KEY_END ) {
            if ( $arg->{order} == 1 && $arg->{rest} ) {
                if (    $arg->{cursor}[ROW] == $#{$arg->{rc2idx}} - 1
                     && $arg->{cursor}[COL] == $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]}
                ) {
                    _beep( $arg );
                }
                else {
                    $arg->{row_on_top} = @{$arg->{rc2idx}} - ( @{$arg->{rc2idx}} % $arg->{avail_height} || $arg->{avail_height} );
                    $arg->{cursor}[ROW] = $#{$arg->{rc2idx}} - 1;
                    $arg->{cursor}[COL] = $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]};
                    if ( $arg->{row_on_top} == $#{$arg->{rc2idx}} ) {
                        $arg->{row_on_top} = $arg->{row_on_top} - $arg->{avail_height};
                        $arg->{p_begin} = $arg->{row_on_top};
                        $arg->{p_end}   = $arg->{p_begin} + $arg->{avail_height} - 1;
                    }
                    else {
                        $arg->{p_begin} = $arg->{row_on_top};
                        $arg->{p_end}   = $#{$arg->{rc2idx}};
                    }
                    _wr_screen( $arg );
                }
            }
            else {
                if (    $arg->{cursor}[ROW] == $#{$arg->{rc2idx}}
                     && $arg->{cursor}[COL] == $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]}
                ) {
                    _beep( $arg );
                }
                else {
                    $arg->{row_on_top} = @{$arg->{rc2idx}} - ( @{$arg->{rc2idx}} % $arg->{avail_height} || $arg->{avail_height} );
                    $arg->{cursor}[ROW] = $#{$arg->{rc2idx}};
                    $arg->{cursor}[COL] = $#{$arg->{rc2idx}[$arg->{cursor}[ROW]]};
                    $arg->{p_begin} = $arg->{row_on_top};
                    $arg->{p_end}   = $#{$arg->{rc2idx}};
                    _wr_screen( $arg );
                }
            }
        }
        elsif ( $key == CONTROL_SPACE ) {
            if ( defined $arg->{wantarray} && $arg->{wantarray} ) {
                for my $i ( 0 .. $#{$arg->{rc2idx}} ) {
                    for my $j ( 0 .. $#{$arg->{rc2idx}[$i]} ) {
                        $arg->{marked}[$i][$j] = $arg->{marked}[$i][$j] ? 0 : 1;
                    }
                }
                _wr_screen( $arg );
            }
        }
        elsif ( $key == KEY_q || $key == CONTROL_D ) {
            return;
        }
        elsif ( $key == CONTROL_C ) {
            $arg->{cC} = 1;
            exit( 1 );
        }
        elsif ( $key == KEY_ENTER ) {
            my @chosen;
            return if ! defined $arg->{wantarray};
            if ( $arg->{wantarray} ) {
                if ( $arg->{order} == 1 ) {
                    for my $col ( 0 .. $#{$arg->{rc2idx}[0]} ) {
                        for my $row ( 0 .. $#{$arg->{rc2idx}} ) {
                            if ( $arg->{marked}[$row][$col] || $row == $arg->{cursor}[ROW] && $col == $arg->{cursor}[COL] ) {
                                my $i = $arg->{rc2idx}[$row][$col];
                                push @chosen, $arg->{index} ? $i : $arg->{orig_list}[$i];
                            }
                        }
                    }
                }
                else {
                    for my $row ( 0 .. $#{$arg->{rc2idx}} ) {
                        for my $col ( 0 .. $#{$arg->{rc2idx}[$row]} ) {
                            if ( $arg->{marked}[$row][$col] || $row == $arg->{cursor}[ROW] && $col == $arg->{cursor}[COL] ) {
                                my $i = $arg->{rc2idx}[$row][$col];
                                push @chosen, $arg->{index} ? $i : $arg->{orig_list}[$i];
                            }
                        }
                    }
                }
                return @chosen;
            }
            else {
                my $i = $arg->{rc2idx}[$arg->{cursor}[ROW]][$arg->{cursor}[COL]];
                return $arg->{index} ? $i : $arg->{orig_list}[$i];
            }
        }
        elsif ( $key == KEY_SPACE ) {
            if ( defined $arg->{wantarray} && $arg->{wantarray} ) {
                if ( ! $arg->{marked}[$arg->{cursor}[ROW]][$arg->{cursor}[COL]] ) {
                    $arg->{marked}[$arg->{cursor}[ROW]][$arg->{cursor}[COL]] = 1;
                }
                else {
                    $arg->{marked}[$arg->{cursor}[ROW]][$arg->{cursor}[COL]] = 0;
                }
                _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] );
            }
        }
        else {
            _beep( $arg );
        }
    }
}


sub _beep {
    my ( $arg ) = @_;
    print BEEP if $arg->{beep};
}


sub _goto {
    my ( $arg, $newrow, $newcol ) = @_;
    if ( $newrow > $arg->{screen_row} ) {
        # with *nix and ReadMode 'ultra-raw':
        # print CR, LF x ( $newrow - $arg->{screen_row} );
        print NL x ( $newrow - $arg->{screen_row} );
        $arg->{screen_row} += ( $newrow - $arg->{screen_row} );
        $arg->{screen_col} = 0;
    }
    elsif ( $newrow < $arg->{screen_row} ) {
        print UP x ( $arg->{screen_row} - $newrow );
        $arg->{screen_row} -= ( $arg->{screen_row} - $newrow );
    }
    if ( $newcol > $arg->{screen_col} ) {
        print RIGHT x ( $newcol - $arg->{screen_col} );
        $arg->{screen_col} += ( $newcol - $arg->{screen_col} );
    }
    elsif ( $newcol < $arg->{screen_col} ) {
        print LEFT x ( $arg->{screen_col} - $newcol );
        $arg->{screen_col} -= ( $arg->{screen_col} - $newcol );
    }
}


sub _wr_screen {
    my ( $arg ) = @_;
    _goto( $arg, 0, 0 );
    print CLEAR_TO_END_OF_SCREEN;
    if ( $arg->{page} && $arg->{pp} > 1 ) {
        _goto( $arg, $arg->{avail_height_idx} + $arg->{tail}, 0 );
        if ( $arg->{pp_printf_type} == 0 ) {
            printf $arg->{pp_printf_fmt}, $arg->{width_pp}, int( $arg->{row_on_top} / $arg->{avail_height} ) + 1, $arg->{pp};
            $arg->{screen_col} += length sprintf $arg->{pp_printf_fmt}, $arg->{width_pp}, int( $arg->{row_on_top} / $arg->{avail_height} ) + 1, $arg->{pp};
        }
        elsif ( $arg->{pp_printf_type} == 1 ) {
            printf $arg->{pp_printf_fmt}, $arg->{width_pp}, $arg->{width_pp}, int( $arg->{row_on_top} / $arg->{avail_height} ) + 1;
            $arg->{screen_col} += length sprintf $arg->{pp_printf_fmt}, $arg->{width_pp}, $arg->{width_pp}, int( $arg->{row_on_top} / $arg->{avail_height} ) + 1;
        }
     }
    for my $row ( $arg->{p_begin} .. $arg->{p_end} ) {
        for my $col ( 0 .. $#{$arg->{rc2idx}[$row]} ) {
            _wr_cell( $arg, $row, $col );
        }
    }
    _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] );
}


sub _wr_cell {
    my( $arg, $row, $col ) = @_;
    if ( $#{$arg->{rc2idx}} == 0 ) {
        my $lngth = 0;
        if ( $col > 0 ) {
            for my $cl ( 0 .. $col - 1 ) {
                my $gcs_element = Unicode::GCString->new( $arg->{list}[$arg->{rc2idx}[$row][$cl]] );
                $lngth += $gcs_element->columns();
                $lngth += $arg->{pad_one_row};
            }
        }
        _goto( $arg, $row - $arg->{row_on_top}, $lngth );
        print BOLD, UNDERLINE if $arg->{marked}[$row][$col];
        print REVERSE         if $row == $arg->{cursor}[ROW] && $col == $arg->{cursor}[COL];
        print $arg->{list}[$arg->{rc2idx}[$row][$col]];
        my $gcs_element = Unicode::GCString->new( $arg->{list}[$arg->{rc2idx}[$row][$col]] );
        $arg->{screen_col} += $gcs_element->columns();
    }
    else {
        _goto( $arg, $row - $arg->{row_on_top}, $col * $arg->{col_width} );
        print BOLD, UNDERLINE if $arg->{marked}[$row][$col];
        print REVERSE         if $row == $arg->{cursor}[ROW] && $col == $arg->{cursor}[COL];
        print Term::Choose::_unicode_sprintf( $arg, $arg->{rc2idx}[$row][$col] );
        $arg->{screen_col} += $arg->{length_longest};
    }
    print RESET if $arg->{marked}[$row][$col] || $row == $arg->{cursor}[ROW] && $col == $arg->{cursor}[COL];
}


sub _handle_mouse {
    my ( $arg, $event_type, $abs_mouse_x, $abs_mouse_y ) = @_;
    my $button_drag = ( $event_type & 0x20 ) >> 5;
    return NEXT_get_key if $button_drag;
    my $button_number;
    my $low_2_bits = $event_type & 0x03;
    if ( $low_2_bits == 3 ) {
        $button_number = 0;
    }
    else {
        if ( $event_type & 0x40 ) {
            $button_number = $low_2_bits + 4; # 4,5
        }
        else {
            $button_number = $low_2_bits + 1; # 1,2,3
        }
    }
    if ( $button_number == 4 ) {
        return KEY_PAGE_UP;
    }
    elsif ( $button_number == 5 ) {
        return KEY_PAGE_DOWN;
    }
    my $pos_top_row = $arg->{abs_cursor_y} - $arg->{cursor_row};
    return NEXT_get_key if $abs_mouse_y < $pos_top_row;
    my $mouse_row = $abs_mouse_y - $pos_top_row;
    my $mouse_col = $abs_mouse_x;
    my( $found_row, $found_col );
    my $found = 0;
    if ( $#{$arg->{rc2idx}} == 0 ) {
        my $row = 0;
        if ( $row == $mouse_row ) {
            my $end_last_col = 0;
            COL: for my $col ( 0 .. $#{$arg->{rc2idx}[$row]} ) {
                my $gcs_element = Unicode::GCString->new( $arg->{list}[$arg->{rc2idx}[$row][$col]] );
                my $end_this_col = $end_last_col + $gcs_element->columns() + $arg->{pad_one_row};
                if ( $col == 0 ) {
                    $end_this_col -= int( $arg->{pad_one_row} / 2 );
                }
                if ( $col == $#{$arg->{rc2idx}[$row]} ) {
                    $end_this_col = $arg->{avail_width} if $end_this_col > $arg->{avail_width};
                }
                if ( $end_last_col < $mouse_col && $end_this_col >= $mouse_col ) {
                    $found = 1;
                    $found_row = $row + $arg->{row_on_top};
                    $found_col = $col;
                    last;
                }
                $end_last_col = $end_this_col;
            }
        }
    }
    else {
        ROW: for my $row ( 0 .. $#{$arg->{rc2idx}} ) {
            if ( $row == $mouse_row ) {
                my $end_last_col = 0;
                COL: for my $col ( 0 .. $#{$arg->{rc2idx}[$row]} ) {
                    my $end_this_col = $end_last_col + $arg->{col_width};
                    if ( $col == 0 ) {
                        $end_this_col -= int( $arg->{pad} / 2 );
                    }
                    if ( $col == $#{$arg->{rc2idx}[$row]} ) {
                        $end_this_col = $arg->{avail_width} if $end_this_col > $arg->{avail_width};
                    }
                    if ( $end_last_col < $mouse_col && $end_this_col >= $mouse_col ) {
                        $found = 1;
                        $found_row = $row + $arg->{row_on_top};
                        $found_col = $col;
                        last ROW;
                    }
                    $end_last_col = $end_this_col;
                }
            }
        }
    }
    return NEXT_get_key if ! $found;
    my $return_char = '';
    if ( $button_number == 1 ) {
        $return_char = KEY_ENTER;
    }
    elsif ( $button_number == 3 ) {
        $return_char = KEY_SPACE;
    }
    else {
        return NEXT_get_key;
    }
    if ( $found_row != $arg->{cursor}[ROW] || $found_col != $arg->{cursor}[COL] ) {
        my $tmp = $arg->{cursor};
        $arg->{cursor} = [ $found_row, $found_col ];
        _wr_cell( $arg, $tmp->[0], $tmp->[1] );
        _wr_cell( $arg, $arg->{cursor}[ROW], $arg->{cursor}[COL] );
    }
    return $return_char;
}


1;

__END__



=pod

=encoding UTF-8

=head1 NAME

Term::Choose::Win32 - Choose items from a list.

=head1 VERSION

Version 0.022

=cut

=head1 ANNOUNCEMENT

If everything works as planned, with the next release of L<Term::Choose>:

- L<Term::Choose::Win32> is removed or replaced by a version which is not expected to be used directly.

- L<Term::Choose> supports MSWin32 OS.

So please read the documentation before upgrading.

This version of c<Term::Choose::Win32> requires the version 1.074 of C<Term::Choose>.

=head1 SYNOPSIS

    use 5.10.0;
    use Term::Choose::Win32 qw(choose);

    my $array_ref = [ qw( one two three four five ) ];

    my $choice = choose( $array_ref );                            # single choice
    say $choice;

    my @choices = choose( [ 1 .. 100 ], { justify => 1 } );       # multiple choice
    say "@choices";

    choose( [ 'Press ENTER to continue' ], { prompt => '' } );    # no choice

=head1 DESCRIPTION

Choose from a list of items.

L<Term::Choose::Win32> is intended for 'MSWin32' operating systems. For other operating system see L<Term::Choose>.

Based on the I<choose> function from the L<Term::Clui> module - for more details see
L<Term::choose/MOTIVATION|https://metacpan.org/module/Term::Choose#MOTIVATION>.

=head1 EXPORT

Nothing by default.

    use Term::Choose::Win32 qw(choose);

=head1 SUBROUTINES

=head2 choose

    $scalar = choose( $array_ref [, \%options] );

    @array =  choose( $array_ref [, \%options] );

              choose( $array_ref [, \%options] );

I<choose> expects as a first argument an array reference. The array the reference refers to holds the list items
available for selection (in void context no selection can be made).

The array the reference - passed with the first argument - refers to is called in the documentation simply array or list
respective elements (of the array).

Options can be passed with a hash reference as a second (optional) argument.

=head3 Usage and return values

=over

=item

If I<choose> is called in a I<scalar context>, the user can choose an item by using the "move-around-keys" and
confirming with "Return".

I<choose> then returns the chosen item.

=item

If I<choose> is called in an I<list context>, the user can also mark an item with the "SpaceBar".

I<choose> then returns - when "Return" is pressed - the list of marked items including the highlighted item.

In I<list context> "Ctrl-SpaceBar" inverts the choices: marked items are unmarked and unmarked items are marked.

=item

If I<choose> is called in an I<void context>, the user can move around but mark nothing; the output shown by I<choose>
can be closed with "Return".

Called in void context I<choose> returns nothing.

=back

If the items of the list don't fit on the screen, the user can scroll to the next (previous) page(s).

If the window size is changed, then as soon as the user enters a keystroke I<choose> rewrites the screen. In list
context marked items are reset.

The "q" key (or Ctrl-D) returns I<undef> or an empty list in list context.

With a I<mouse> mode enabled (and if supported by the terminal) the item can be chosen with the left mouse key, in list
context the right mouse key can be used instead the "SpaceBar" key.

=head3 Keys to move around:

=over

=item *

Arrow keys (or hjkl),

=item *

Tab key (or Ctrl-I) to move forward, BackSpace key (or Ctrl-H or Shift-Tab) to move backward,

=item *

PageUp key (or Ctrl-B) to go back one page, PageDown key (or Ctrl-F) to go forward one page,

=item *

Home key (or Ctrl-A) to jump to the beginning of the list, End key (or Ctrl-E) to jump to the end of the list.

=back

=head3 Modifications for the output

For the output on the screen the array elements are modified:

=over

=item *

if an element is not defined the value from the option I<undef> is assigned to the element.

=item *

if an element holds an empty string the value from the option I<empty> is assigned to the element.

=item *

white-spaces in elements are replaced with simple spaces.

    $element =~ s/\p{Space}/ /g;

=item *

characters which match the Unicode character property I<Other> are removed.

    $element =~ s/\p{C}//g;

=item *

if the length of an element is greater than the width of the screen the element is cut.

    $element = substr( $element, 0, $allowed_length - 3 ) . '...';*

* L<Term::Choose::Win32> uses its own function to cut strings which uses print columns for the arithmetic.

=back

All these modifications are made on a copy of the original array so I<choose> returns the chosen elements as they were
passed to the function without modifications.

=head3 Options

Options which expect a number as their value expect integers.

=head4 prompt

If I<prompt> is undefined a default prompt-string will be shown.

If the I<prompt> value is an empty string ("") no prompt-line will be shown.

default in list and scalar context: 'Your choice:'

default in void context: 'Close with ENTER'

=head4 layout

From broad to narrow: 0 > 1 > 2 > 3

=over

=item

0 - layout off

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |
 |                      |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. .. .. ..       |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=item

1 - layout "H" (default)

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | .. .. .. .. .. .. .. |   | .. .. .. .. ..       |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   | .. .. .. .. ..       |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   | .. ..                |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. ..             |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=item

2 - layout "V"

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | ..                   |   | .. ..                |   | .. .. .. ..          |   | .. .. .. .. .. .. .. |
 | ..                   |   | .. ..                |   | .. .. .. ..          |   | .. .. .. .. .. .. .. |
 | ..                   |   | .. ..                |   | .. .. .. ..          |   | .. .. .. .. .. .. .. |
 | ..                   |   | ..                   |   | .. .. ..             |   | .. .. .. .. .. .. .. |
 | ..                   |   |                      |   | .. .. ..             |   | .. .. .. .. .. .. .. |
 | ..                   |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=item

3 - all in a single column

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 |                      |   | ..                   |   | ..                   |   | ..                   |
 |                      |   |                      |   | ..                   |   | ..                   |
 |                      |   |                      |   |                      |   | ..                   |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=back

=head4 max_height

If defined sets the maximal number of rows used for printing list items.

If the available height is less than I<max_height> I<max_height> is set to the available height.

Height in this context means print rows.

I<max_height> overwrites I<keep> if I<max_height> is set and less than I<keep>.

Allowed values: 1 or greater

(default: undef)

=head4 max_width

If defined, sets the output width to I<max_width> if the terminal width is greater than I<max_width>.

Width refers here to the number of print columns.

Allowed values: 1 or greater

(default: undef)

=head4 order

If the output has more than one row and more than one column:

0 - elements are ordered horizontally

1 - elements are ordered vertically (default)

Default may change in a future release.

=head4 justify

0 - elements ordered in columns are left justified (default)

1 - elements ordered in columns are right justified

2 - elements ordered in columns are centered

=head4 pad

Sets the number of whitespaces between columns. (default: 2)

Allowed values: 0 or greater

=head4 pad_one_row

Sets the number of whitespaces between elements if we have only one row. (default: value of the option I<pad>)

Allowed values: 0 or greater

=head4 clear_screen

0 - off (default)

1 - clears the screen before printing the choices

=head4 default

With the option I<default> it can be selected an element, which will be highlighted as the default instead of the first
element.

I<default> expects a zero indexed value, so e.g. to highlight the third element the value would be I<2>.

If the passed value is greater than the index of the last array element the first element is highlighted.

Allowed values: 0 or greater

(default: undef)

=head4 index

0 - off (default)

1 - return the index of the chosen element instead of the chosen element respective the indices of the chosen elements
instead of the chosen elements.

=head4 page

0 - off

1 - print the page number on the bottom of the screen if there is more then one page. (default)

=head4 mouse

0 - no mouse mode (default)

1 - mouse mode enabled

2 - mouse mode enabled; the output width is limited to 223 print-columns and the height to 223 rows

Mouse mode 3 and 4 behave like mouse mode 1.

=head4 keep

I<keep> prevents that all the terminal rows are used by the prompt lines.

Setting I<keep> ensures that at least I<keep> terminal rows are available for printing list rows.

If the terminal height is less than I<keep> I<keep> is set to the terminal height.

Allowed values: 1 or greater

(default: 5)

=head4 beep

0 - off (default)

1 - on

=head4 hide_cursor

0 - keep the terminals highlighting of the cursor position

1 - hide the terminals highlighting of the cursor position (default)

=head4 limit

Sets the maximal allowed length of the array. (default: undef)

If the array referred by the first argument has more than limit elements choose uses only the first limit array
elements.

Allowed values: 1 or greater

=head4 undef

Sets the string displayed on the screen instead an undefined element.

default: '<undef>'

=head4 empty

Sets the string displayed on the screen instead an empty string.

default: '<empty>'

=head4 lf

If I<prompt> lines are folded the option I<lf> allows to insert spaces at beginning of the folded lines.

The option I<lf> expects a reference to an array with two elements;

- first element (INITIAL_TAB): the number of spaces inserted at beginning of paragraphs

- second element (SUBSEQUENT_TAB): the number of spaces inserted at the beginning of all broken lines apart from the
beginning of paragraphs

Allowed values for the two elements are: 0 or greater.

See INITIAL_TAB and SUBSEQUENT_TAB in L<Text::LineFold>.

(default: undef)

=head4 ll

If all elements have the same length and this length is known before calling I<choose> the length can be passed with
this option.

If I<ll> is set, then I<choose> doesn't calculate the length of the longest element itself but uses the value passed
with this option.

I<length> refers here to the number of print columns the element will use on the terminal.

A way to determine the number of print columns is the use of I<columns> from L<Unicode::GCString>.

The length of undefined elements and elements with an empty string depends on the value of the option I<undef>
respective on the value of the option I<empty>.

If the option I<ll> is set the replacements described in L</Modifications for the output> are not applied.

If elements contain unsupported characters the output might break if the width (number of print columns) of the
replacement character does not correspond to the width of the replaced character - for example when a unsupported
non-spacing character is replaced by a replacement character with a normal width.

I<ll> is set to a value less than the length of the elements the output could break.

If the value of I<ll> is greater than the screen width the elements will be trimmed to fit into the screen.

Allowed values: 1 or greater

(default: undef)

=head3 Error handling

=over

=item * With no arguments I<choose> dies.

=item * With more than two arguments I<choose> dies.

=item * If the first argument is not a array reference I<choose> dies.

=item * If the array referred by the first argument is empty I<choose> returns I<undef> respective an empty list and
issues a warning.

=item * If the (optional) second argument is defined and not a hash reference I<choose> dies.

=item * If an option does not exist I<choose> warns.

=item * If an option value is not valid I<choose> warns an falls back to the default value.

=item * If after pressing a key L<Term::ReadKey>::ReadKey returns I<undef> I<choose> warns with "EOT: $!" and returns
I<undef> or an empty list in list context.

=back

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.10.1 or greater.

=head2 Modules

Used modules not provided as core modules:

=over

=item

L<Term::Choose>

=item

L<Term::Size::Win32>

=item

L<Unicode::GCString>

=item

L<Win32::Console>

=item

L<Win32::Console::ANSI>

=back

=head2 Decoded strings

I<choose> expects decoded strings as array elements.

L<Term::Choose::Win32> disables the automatic conversion done by L<Win32::Console::ANSI> globally.

=head2 encoding layer for STDOUT

For a correct output it is required to set an encoding layer for STDOUT matching the terminal's character set.

=head2 Monospaced font

It is required a terminal that uses a monospaced font which supports the printed characters.

=head2 Escape sequences

L<Term::Choose::Win32> uses the following ANSI escape sequences:

    "\e[A"      Cursor Up

    "\e[C"      Cursor Forward

    "\e[D"      Cursor Back

    "\e[0J"     Clear to End of Screen (Erase Data)

    "\e[0m"     Normal/Reset

    "\e[1m"     Bold

    "\e[4m"     Underline

    "\e[7m"     Inverse

If the option "hide_cursor" is enabled:

    "\e[?25l"   Hide Cursor

    "\e[?25h"   Show Cursor

To understand these escape sequences L<Term::Choose::Win32> uses the L<Win32::Console::ANSI> module.

The L<Win32::Console::ANSI> Cursor() function is used to get the cursor position.

To read key and mouse events L<Term::Choose::Win32> uses L<Win32::Console>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Choose::Win32

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Based on and inspired by the I<choose> function from the L<Term::Clui> module.

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2014 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
