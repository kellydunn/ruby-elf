# Simple ELF parser for Ruby
#
# Copyright 2007 Diego Pettenò <flameeyes@gmail.com>
# Portions inspired by elf.py
#   Copyright 2002 Netgraft Corporation
# Portions inspired by elf.h
#   Copyright 1995-2006 Free Software Foundation, Inc.
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

require 'bytestream-reader'

class Elf
  class File < BytestreamReader
    class NotAnELF < Exception
      def message
        "The file is not an ELF file."
      end
    end

    class Type < Value
      fill({
             0 => [ :None, 'No file type' ],
             1 => [ :Rel, 'Relocatable file' ],
             2 => [ :Exec, 'Executable file' ],
             3 => [ :Dyn, 'Shared object file' ],
             4 => [ :Core, 'Core file' ],
             0xfe00 => [ :LoOs, 'OS-specific range start' ],
             0xfeff => [ :HiOs, 'OS-specific range end' ],
             0xff00 => [ :LoProc, 'Processor-specific range start' ],
             0xffff => [ :HiProc, 'Processor-specific range end' ]
           })
    end

    attr_reader :elf_class, :data_encoding, :type, :version, :abi,
                :abi_version, :machine
    attr_reader :string_table
    attr_reader :sections

    def initialize(path)
      super(path, "rb")

      raise NotAnELF unless readbytes(4) == MagicString

      @elf_class = Class[read_u8]
      @data_encoding = DataEncoding[read_u8]
      @version = read_u8
      @abi = OsAbi[read_u8]
      @abi_version = read_u8

      seek(16, IO::SEEK_SET)
      set_endian(DataEncoding::BytestreamMapping[@data_encoding])

      alias :read_half :read_u16

      alias :read_word :read_u32
      alias :read_sword :read_s32

      alias :read_xword :read_u64
      alias :read_sxword :read_s64

      alias :read_section :read_u16
      alias :read_versym :read_half
      
      case @elf_class
      when Class::Elf32
        alias :read_addr :read_u32
        alias :read_off :read_u32
      when Class::Elf64
        alias :read_addr :read_u64
        alias :read_off :read_u64
      end

      @type = Type[read_half]
      @machine = Machine[read_half]
      @version = read_word
      @entry = read_addr
      @phoff = read_off
      shoff = read_off
      @flags = read_word
      @ehsize = read_half
      @phentsize = read_half
      @phnum = read_half
      @shentsize = read_half
      shnum = read_half
      shstrndx = read_half

      sections = []
      seek(shoff)
      for i in 1..shnum
        sections << Section.read(self)
      end

      @string_table = sections[shstrndx]
      raise Exception unless @string_table.class == StringTable

      @sections = {}
      sections.each_index do |idx|
        @sections[idx] = sections[idx]
        @sections[sections[idx].name] = sections[idx]
      end
    end

    def summary
      $stdout.puts "ELF file #{path}"
      $stdout.puts "ELF class: #{@elf_class} #{@data_encoding} ver. #{@version}"
      $stdout.puts "ELF ABI: #{@abi} ver. #{@abi_version}"
      $stdout.puts "ELF type: #{@type} machine: #{@machine}"
      $stdout.puts "Sections:"
      @sections.values.uniq.each do |sh|
        sh.summary
      end

      return nil
    end
  end
end