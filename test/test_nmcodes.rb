# -*- coding: utf-8 -*-
# Copyright © 2008-2010 Diego Elio Pettenò <flameeyes@flameeyes.eu>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this generator; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'tt_elf'

# Tests for nm(1)-style codes support in Ruby-Elf
#
# This test will load the file built from the symboltypes.c source
# file and will ensure that the symbols in there reports the correct
# nm(1)-style code.
module Elf::TestNMCodes
  include Elf::BaseTest
  BaseFilename = "symboltypes.o"

  def dotest_symbols(table)
    table.each_pair do |sym, code|
      assert_equal code, @elf[".symtab"][sym].nm_code, "Testing #{sym}"
    end
  end

  def test_first_idx
    assert_equal " ", @elf[".symtab"][0].nm_code, "Testing first symbol"
  end

  def test_absolute
    dotest_symbols({ "symboltypes.c"     => 'a' })
  end

  # Test the general symbols
  def test_general
    dotest_symbols({ "external_function" => 'T',
                     "static_function"   => 't' })
  end

  # Test variables
  def test_variables
    dotest_symbols({ "external_variable"               => 'D',
                     "relocated_external_variable"     => 'D',
                     "external_uninitialised_variable" => 'C' })
  end

  # Test TLS variables
  def test_tls
    dotest_symbols({ "external_tls_variable"               => 'D',
                     "external_uninitialised_tls_variable" => 'B',
                     "relocated_external_tls_variable"     => 'D' })
  end

  # Test constants
  def test_constants
    dotest_symbols({ "external_constant"           => 'R',
                     "relocated_external_constant" => 'D' })
  end

  # Test static declarations
  def test_static
    dotest_symbols({ "static_variable"                   => 'd',
                     "relocated_static_variable"         => 'd',
                     "static_uninitialised_variable"     => 'b',
                     "static_uninitialised_tls_variable" => 'b',
                     "static_tls_variable"               => 'd',
                     "relocated_static_constant"         => 'd',
                     "static_constant"                   => 'r' })
  end

  def test_undefined
    dotest_symbols({
                     "undefined_external_variable" => 'U'
                   })
  end

  def test_weakrefs
    dotest_symbols({
                     "weak_reference_to_variable" => 'V',
                     "weak_reference_to_function" => 'W'
                   })
  end

  def test_gnu
    dotest_symbols({
                     "gnu_function" => 'i',
                     "gnu_unique_object" => 'u'
                   })
  end

  module ICC
    Compiler = "icc"

    # For some reason ICC adds a .0 to unit-static symbols
    def test_static
      dotest_symbols({ "static_variable.0"                   => 'd',
                       "relocated_static_variable.0"         => 'd',
# For some reason, ICC does not emit these variables (?!)                       
#                       "static_uninitialised_variable.0"     => 'b',
#                       "static_uninitialised_tls_variable.0" => 'b',
                       "static_tls_variable.0"               => 'd',
                       "relocated_static_tls_variable.0"     => 'd',
                       "relocated_static_constant.0"         => 'd',
                       "static_constant.0"                   => 'r' })
    end
  end

  module GCC
    Compiler = "gcc"
    def test_hot_cold_functions
      dotest_symbols({ "external_cold_function" => 'T',
                       "static_cold_function"   => 't',
                       "external_hot_function"  => 'T',
                       "static_hot_function"    => 't' })
    end
  end

  # Test section names symbols
  #
  # Each section in an ELF file has its equivalent symbol name, test
  # the presence of (some) section names in symbols and their value
  #
  # TODO: these symbols don't appear to be loaded by ruby-elf!
  # def test_sections
  #   dotest_symbols({ ".bss"               => 'b',
  #                    ".comment"           => 'n',
  #                    ".data"              => 'd',
  #                    ".data.rel.local"    => 'd',
  #                    ".data.rel.ro.local" => 'd',
  #                    ".eh_frame"          => 'r',
  #                    ".note.GNU-stack"    => 'n',
  #                    ".rodata"            => 'r',
  #                    ".tss"               => 'b',
  #                    ".tdata"             => 'd',
  #                    ".text"              => 't' })
  # end

  class LinuxAMD64 < Test::Unit::TestCase
    include GCC
    include Elf::TestNMCodes
    include Elf::TestExecutable::LinuxAMD64
  end

  class LinuxAMD64_ICC < Test::Unit::TestCase
    include Elf::TestNMCodes
    include Elf::TestExecutable::LinuxAMD64
    include ICC

    # require rebuilding the object file
    undef :test_undefined, :test_weakrefs, :test_gnu
  end

  class LinuxAMD64_SunStudio < Test::Unit::TestCase
    include Elf::TestNMCodes
    include Elf::TestExecutable::LinuxAMD64
    Compiler = "suncc"

    # Sun Studio generates different code!
    def test_tls
      dotest_symbols({ "external_tls_variable"               => 'D',
                       "static_tls_variable"                 => 'd',
                       "external_uninitialised_tls_variable" => 'C',
                       "static_uninitialised_tls_variable"   => 'b',
                       "relocated_external_tls_variable"     => 'D',
                       "relocated_static_tls_variable"       => 'd' })
    end

    # require rebuilding the object file
    undef :test_undefined, :test_weakrefs, :test_gnu
  end

  class LinuxAMD64_Path64 < Test::Unit::TestCase
    include Elf::TestNMCodes
    include Elf::TestExecutable::LinuxAMD64
    Compiler = "path64"

    undef :test_absolute
  end

  class SolarisX86_SunStudio < Test::Unit::TestCase
    include Elf::TestNMCodes
    include Elf::TestExecutable::SolarisX86_SunStudio

    # Sun Studio generates different code!
    def test_tls
      dotest_symbols({ "external_tls_variable"               => 'D',
                       "static_tls_variable"                 => 'd',
                       "external_uninitialised_tls_variable" => 'C',
                       "static_uninitialised_tls_variable"   => 'b',
                       "relocated_external_tls_variable"     => 'D',
                       "relocated_static_tls_variable"       => 'd' })
    end

    # require rebuilding the object file
    undef :test_undefined, :test_weakrefs, :test_gnu
  end
end
