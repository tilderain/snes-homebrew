#!/usr/bin/env python3
"""
TCC816 (pvsneslib) compilation wrapper script - Linux/Cross-Platform Fix
Copies source files to build directory and runs TCC816 -> 816-opt -> Constify -> WLA
"""

import os
import sys
import subprocess
import argparse
import shutil
import platform

def get_executable_name(name):
    """Returns the executable name with .exe extension if on Windows"""
    if platform.system() == "Windows":
        return f"{name}.exe"
    return name

def run_command(cmd, cwd=None, stdout=None):
    """Helper to run subprocess commands with error handling"""
    # If stdout is a file object, pass it directly
    try:
        if stdout and hasattr(stdout, 'write'):
            result = subprocess.run(cmd, stdout=stdout, stderr=subprocess.PIPE, text=True, cwd=cwd)
        else:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)

        if result.returncode != 0:
            print(f"Error executing: {' '.join(cmd)}")
            if not (stdout and hasattr(stdout, 'write')):
                print("STDOUT:", result.stdout)
            print("STDERR:", result.stderr)
            sys.exit(result.returncode)
        return result
    except Exception as e:
        print(f"Exception executing {' '.join(cmd)}: {e}")
        sys.exit(1)

def main():
    print("TCC816 wrapper starting...")
    
    # 1. Setup Paths
    pvsneslib_home = os.environ.get("PVSNESLIB_HOME")
    if not pvsneslib_home:
        if os.path.exists("/opt/pvsneslib"):
            pvsneslib_home = "/opt/pvsneslib"
        else:
            print("Error: PVSNESLIB_HOME environment variable is not set.")
            sys.exit(1)

    devkit_snes_path = os.path.join(pvsneslib_home, "devkitsnes", "bin")
    c_inc_path = os.path.join(pvsneslib_home, "devkitsnes", "include")
    tools_path = os.path.join(pvsneslib_home, "devkitsnes", "tools")

    os.environ["PVSNESLIB_HOME"] = pvsneslib_home
    os.environ["PATH"] = devkit_snes_path + os.pathsep + \
                         c_inc_path + os.pathsep + \
                         tools_path + os.pathsep + \
                         os.environ["PATH"]
    
    work_dir = os.getcwd()
    build_dir = os.path.join(work_dir, "build")
    os.makedirs(build_dir, exist_ok=True)
    
    # 2. Parse Arguments
    parser = argparse.ArgumentParser(description='TCC816 compilation wrapper')
    parser.add_argument('-o', '--output', help='Output file')
    parser.add_argument('-V', '--verbose', action='store_true', help='Verbose output')
    parser.add_argument('sources', nargs='*', help='Source files')
    args, unknown = parser.parse_known_args()
    
    # 3. Locate Tools
    tcc816_bin = os.path.join(devkit_snes_path, get_executable_name("816-tcc"))
    opt816_bin = os.path.join(tools_path, get_executable_name("816-opt"))
    constify_bin = os.path.join(tools_path, get_executable_name("constify"))

    # Validate tools exist
    for tool in [tcc816_bin, opt816_bin, constify_bin]:
        if not os.path.exists(tool):
            print(f"Error: Tool not found at {tool}")
            sys.exit(1)

    # 4. Copy Sources
    c_sources = [] # Files to run through C pipeline
    asm_sources = [] # Pure ASM files to pass to linker directly
    
    # Collect all sources from args and unknown args
    raw_sources = args.sources + [arg for arg in unknown if not arg.startswith('-') and (arg.endswith('.c') or arg.endswith('.asm'))]
    
    for source in raw_sources:
        if 'build' in source and source.endswith('.o'): continue # Skip build artifacts
        
        full_source_path = os.path.normpath(os.path.join(work_dir, source))
        
        if os.path.isfile(full_source_path):
            dest_filename = os.path.basename(source)
            dest_path = os.path.join(build_dir, dest_filename)
            shutil.copy2(full_source_path, dest_path)
            
            if source.endswith('.c'):
                c_sources.append(dest_filename)
            elif source.endswith('.asm'):
                asm_sources.append(dest_filename)
            print(f"Copied: {source}")
        else:
            print(f"Warning: Source file not found: {full_source_path}")

    # Copy standard headers
    header_files = ["snes_regs_xc.h", "int_snes_xc.h"]
    for header_file in header_files:
        h_path = os.path.join(work_dir, "..", "shared", "src", header_file)
        if os.path.exists(h_path):
            shutil.copy2(h_path, os.path.join(build_dir, header_file))

    # 5. Build Include Flags
    include_flags = ["-I" + os.path.join(pvsneslib_home, "pvsneslib", "include"), "-I" + c_inc_path]
    i = 0
    while i < len(unknown):
        if unknown[i] == "-I" and i + 1 < len(unknown):
            include_flags.extend(["-I", os.path.normpath(os.path.join(work_dir, unknown[i + 1]))])
            i += 2
        elif unknown[i].startswith("-I"):
            include_flags.extend(["-I", os.path.normpath(os.path.join(work_dir, unknown[i][2:]))])
            i += 1
        else:
            i += 1

    # 6. Compilation Pipeline (C -> PS -> ASP -> ASM)
    generated_asm_files = []

    for c_file in c_sources:
        base_name = os.path.splitext(c_file)[0]
        ps_file = f"{base_name}.ps"
        asp_file = f"{base_name}.asp"
        asm_file = f"{base_name}.asm"

        print(f"--- Processing {c_file} ---")

        # Step A: TCC816 (Compile to .ps)
        # Note: We rely on default CFLAGS logic roughly similar to makefile
        # Adding -D__TCC816__ is standard
        tcc_cmd = [tcc816_bin] + include_flags + ["-D__TCC816__", "-c", c_file, "-o", ps_file]
        print(f"1. Compiling: {c_file} -> {ps_file}")
        run_command(tcc_cmd, cwd=build_dir)

        # Step B: 816-opt (Optimize .ps -> .asp)
        # 816-opt reads input file and outputs to STDOUT
        print(f"2. Optimizing: {ps_file} -> {asp_file}")
        opt_cmd = [opt816_bin, ps_file]
        with open(os.path.join(build_dir, asp_file), 'w') as f_out:
            run_command(opt_cmd, cwd=build_dir, stdout=f_out)

        # Step C: Constify (Move constants, C + ASP -> ASM)
        print(f"3. Constifying: {c_file} + {asp_file} -> {asm_file}")
        ctf_cmd = [constify_bin, c_file, asp_file, asm_file]
        run_command(ctf_cmd, cwd=build_dir)
        
        generated_asm_files.append(asm_file)
        
        # Cleanup intermediate files
        try:
            os.remove(os.path.join(build_dir, ps_file))
            os.remove(os.path.join(build_dir, asp_file))
        except OSError:
            pass

    # 7. Convert ASM to OBJ and Link
    # Combine generated ASM files from C and pure ASM files copied over
    all_asm_to_process = generated_asm_files + asm_sources
    
    if all_asm_to_process:
        print("--- Assembly and Linking ---")
        convert_and_link(build_dir, all_asm_to_process, devkit_snes_path, pvsneslib_home)
    else:
        print("No source files processed.")
        sys.exit(1)

def convert_and_link(build_dir, asm_files, devkit_path, pvsneslib_home):
    """Convert assembly files to object files and link into a SNES ROM"""
    try:
        # Setup Header
        port_dir = os.path.dirname(os.path.abspath(__file__))
        hdr_source = os.path.join(port_dir, "hdr.asm")
        hdr_dest = os.path.join(build_dir, "hdr.asm")
        
        if os.path.exists(hdr_source):
            shutil.copy2(hdr_source, hdr_dest)
        else:
            create_default_header(hdr_dest)
        
        wla_bin = get_executable_name("wla-65816")
        wla_path = os.path.join(devkit_path, wla_bin)
        
        obj_files = []
        
        # 1. Assemble Header
        hdr_obj = "hdr.obj"
        hdr_cmd = [wla_path, "-d", "-s", "-x", "-o", hdr_obj, "hdr.asm"]
        print(f"Assembling header...")
        run_command(hdr_cmd, cwd=build_dir)
        obj_files.append(hdr_obj)
        
        # 2. Assemble Sources
        for asm_file in asm_files:
            # Avoid processing hdr.asm twice if it was in sources list
            if asm_file == "hdr.asm": continue
            
            obj_file = os.path.splitext(asm_file)[0] + '.obj'
            # -d: disable calculation ability (prevents specific WLA errors with labels)
            # -s: symbols
            # -x: eXport
            asm_cmd = [wla_path, "-d", "-s", "-x", "-o", obj_file, asm_file]
            
            print(f"Assembling {asm_file} -> {obj_file}")
            run_command(asm_cmd, cwd=build_dir)
            obj_files.append(obj_file)
        
        # 3. Link
        if obj_files:
            link_rom(build_dir, obj_files, devkit_path, pvsneslib_home)
            
    except Exception as e:
        print(f"Error during conversion and linking: {e}")
        sys.exit(1)

def link_rom(build_dir, obj_files, devkit_path, pvsneslib_home):
    """Link object files into a SNES ROM using WLA-65816"""
    try:
        linkfile_path = os.path.join(build_dir, "linkfile")
        # Defaulting to LoROM_SlowROM as per common defaults, 
        # normally strictly controlled by Makefile HIROM/FASTROM flags
        lib_dir = os.path.join(pvsneslib_home, "pvsneslib", "lib", "LoROM_SlowROM")
        
        with open(linkfile_path, 'w') as f:
            f.write("[objects]\n")
            for obj_file in obj_files:
                f.write(f"{obj_file}\n")
            
            # Add pvsneslib library objects
            if os.path.exists(lib_dir):
                for lib_file in os.listdir(lib_dir):
                    if lib_file.endswith('.obj'):
                        full_lib_path = os.path.join(lib_dir, lib_file).replace("\\", "/")
                        f.write(f"{full_lib_path}\n")
        
        wlalink_bin = get_executable_name("wlalink")
        wlalink_path = os.path.join(devkit_path, wlalink_bin)
        
        rom_filename = "main.sfc"
        link_cmd = [wlalink_path, "-d", "-s", "-v", "-A", "-c", "-L", lib_dir, "linkfile", rom_filename]
        
        print(f"Linking... -> {rom_filename}")
        run_command(link_cmd, cwd=build_dir)
        
        print(f"SUCCESS! ROM created at: {os.path.join(build_dir, rom_filename)}")
            
    except Exception as e:
        print(f"Error during linking: {e}")
        sys.exit(1)

def create_default_header(path):
    """Writes the default SNES header if one isn't found"""
    content = ''';==LoRom==
.MEMORYMAP
  SLOTSIZE $8000
  DEFAULTSLOT 0
  SLOT 0 $8000
  SLOT 1 $0 $2000
  SLOT 2 $2000 $E000
  SLOT 3 $0 $10000
.ENDME
.ROMBANKSIZE $8000
.ROMBANKS 8
.SNESHEADER
  ID "SNES"
  NAME "TCC816 TEST ROM      "
  SLOWROM
  LOROM
  CARTRIDGETYPE $00
  ROMSIZE $08
  SRAMSIZE $00
  COUNTRY $01
  LICENSEECODE $00
  VERSION $00
.ENDSNES
.SNESNATIVEVECTOR
  COP EmptyHandler
  BRK EmptyHandler
  ABORT EmptyHandler
  NMI VBlank
  IRQ EmptyHandler
.ENDNATIVEVECTOR
.SNESEMUVECTOR
  COP EmptyHandler
  ABORT EmptyHandler
  NMI EmptyHandler
  RESET tcc__start
  IRQBRK EmptyHandler
.ENDEMUVECTOR
EmptyHandler:
  rti
VBlank:
  rti
.BANK 0 SLOT 0
.ORG $0000
'''
    with open(path, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    main()
