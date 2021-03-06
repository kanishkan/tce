//
// TCE Baseopset instruction information.
//
// Author: Veli-Pekka J��skel�inen 2007 (vjaaskel@cs.tut.fi)
// Author: Mikael Lepist� 2009 (mikael.lepisto@tut.fi)
// Author: Heikki Kultala 2012 (heikki.kultala@tut.fi)
//

def LittleEndian : Predicate<"subtarget_.isLittleEndian()">;
def BigEndian : Predicate<"!subtarget_.isLittleEndian()">;
def Bitness64 : Predicate<"subtarget_.is64bit()">;
def Bitness32 : Predicate<"!subtarget_.is64bit()">;
def LE32 : Predicate<"(!subtarget_.is64bit() && subtarget_.isLittleEndian())">;

include "GenInstrInfo0.td"

def TCESRAConst : SDNode<"TCEISD::SRA_Const", SDTIntBinOp, []>;
def TCESRLConst : SDNode<"TCEISD::SRL_Const", SDTIntBinOp, []>;
def TCESHLConst : SDNode<"TCEISD::SHL_Const", SDTIntBinOp, []>;

// Operand for printing out a condition code.
let PrintMethod = "printCCOperand" in
  def CCOp : Operand<i32>;

def SDTTCEFTOI :
SDTypeProfile<1, 1, [SDTCisVT<0, f32>, SDTCisFP<1>]>;

def SDTTCEITOF :
SDTypeProfile<1, 1, [SDTCisFP<0>, SDTCisVT<1, f32>]>;

def TCEftoi  : SDNode<"TCEISD::FTOI", SDTTCEFTOI>;
def TCEitof  : SDNode<"TCEISD::ITOF", SDTTCEITOF>;

// These are target-independent nodes, but have target-specific formats.
def SDT_TCECallSeqEnd   : SDCallSeqEnd<[ SDTCisVT<0, i32>,
                                        SDTCisVT<1, i32> ]>;

def callseq_end   : SDNode<"ISD::CALLSEQ_END",   SDT_TCECallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def call          : SDNode<"TCEISD::CALL", SDT_TCECall,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def retflag       : SDNode<"TCEISD::RET_FLAG", SDTNone,
                           [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// =========================
//  Pseudo instructions
// =========================

let Defs = [SP], Uses = [SP] in {
def ADJCALLSTACKUP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                            "# ADJCALLSTACKUP $amt1",
                            [(callseq_end timm:$amt1, timm:$amt2)]>;
}

// =========================
//  Moves
// =========================

include "GenOperandInfo.td"

// Immediate writes to register
def f16imm   : Operand<f16>;
let isReMaterializable = 1, isMoveImm = 1 in {

def MOVI1ri : InstTCE<
    (outs R1Regs:$dst), (ins i1imm:$val),
    "$src -> $dst;",
    [(set R1Regs:$dst, (i1 imm:$val))]>;

def MOVGri : InstTCE<
    (outs GuardRegs:$dst), (ins i1imm:$val),
    "$src -> $dst;",
    [(set GuardRegs:$dst, (i1 imm:$val))]>;

def PRED_TRUE_MOVI1ri : InstTCE<
    (outs R1Regs:$dst), (ins GuardRegs:$pred, i1imm:$val),
    "$src -> $dst;",
    []>;

def PRED_FALSE_MOVI1ri : InstTCE<
    (outs R1Regs:$dst), (ins GuardRegs:$pred, i1imm:$val),
    "$src -> $dst;",
    []>;

// i32MoveImm definition is generated in GenOperandInfo.td
def MOVI32ri : InstTCE<(outs R32IRegs:$dst), (ins i32imm:$src),
	           "$src -> $dst;",
                   [(set R32IRegs:$dst, i32MoveImm:$src)]>, Requires<[Bitness32]>;

def MOVI64sa : InstTCE<(outs R64IRegs:$dst), (ins i64imm:$src),
                   "$src -> $dst;",
                   [(set R64IRegs:$dst, i64MoveImm:$src)]>, Requires<[Bitness64]>;

def PRED_TRUE_MOVI64sa : InstTCE<(outs R64IRegs:$dst),
                   (ins R1Regs:$pred, i64imm:$src),
                   "$src -> $dst;", []>;

def PRED_FALSE_MOVI64sa : InstTCE<(outs R64IRegs:$dst),
                   (ins R1Regs:$pred, i64imm:$src),
                   "$src -> $dst;", []>;

def PRED_TRUE_MOVI32ri : InstTCE<(outs R32IRegs:$dst), 
                      (ins GuardRegs:$pred, i32MoveImm:$src),
	           	   "$src -> $dst;", []>;

def PRED_FALSE_MOVI32ri : InstTCE<(outs R32IRegs:$dst), 
                      (ins GuardRegs:$pred, i32MoveImm:$src),
	           	   "$src -> $dst;", []>;

def MOVfk : InstTCE<(outs FPRegs:$dst), (ins f32imm:$val),
	           "$val -> $dst;",
                   [(set FPRegs:$dst, (f32 fpimm:$val))]>;
def MOVhk : InstTCE<(outs HFPRegs:$dst), (ins f16imm:$val),
	           "$src -> $dst;",
                   [(set HFPRegs:$dst, (f16 fpimm:$val))]>;
}

// TODO: are these really ever used for anything? propably not?
let isReMaterializable = 1, isMoveImm = 1 in {
def MOVfi : InstTCE<(outs FPRegs:$dst), (ins i32imm:$src),
	           "$src -> $dst;",
                   []>;
def MOVhi : InstTCE<(outs HFPRegs:$dst), (ins i32imm:$src),
	           "$src -> $dst;",
                   []>;
}

let isAsCheapAsAMove = 1 in {

// Int -> Int register moves.
def MOVI1rr : InstTCE<(outs R1Regs:$dst), (ins R1Regs:$src),
	           "$src -> $dst;",
                   []>;

def PRED_TRUE_MOVI1rr : InstTCE<(outs R1Regs:$dst), 
    (ins GuardRegs:$pred, R1Regs:$src),
	           "$src -> $dst;",
                   []>;

def PRED_FALSE_MOVI1rr : InstTCE<(outs R1Regs:$dst), 
    (ins GuardRegs:$pred, R1Regs:$src),
	           "$src -> $dst;",
                   []>;

def MOVI32rr : InstTCE<(outs R32IRegs:$dst), (ins R32IRegs:$src),
	           "$src -> $dst;",
                   []>;

def PRED_TRUE_MOVI32rr : InstTCE<(outs R32IRegs:$dst), 
    (ins GuardRegs:$pred, R32IRegs:$src),
	           "$src -> $dst;",
                   []>;

def PRED_FALSE_MOVI32rr : InstTCE<(outs R32IRegs:$dst), 
    (ins GuardRegs:$pred, R32IRegs:$src),
	           "$src -> $dst;",
                   []>;

def MOV64ss : InstTCE<(outs R64Regs:$dst), (ins R64Regs:$src),
	           "$src -> $dst;",
                   []>, Requires<[Bitness64]>;

def PRED_TRUE_MOV64ss : InstTCE<(outs R64Regs:$dst),
    (ins R1Regs:$pred, R64Regs:$src),
	           "$src -> $dst;",
                   []>, Requires<[Bitness64]>;

def PRED_FALSE_MOV64ss : InstTCE<(outs R64Regs:$dst),
    (ins R1Regs:$pred, R64Regs:$src),
	           "$src -> $dst;",
                   []>, Requires<[Bitness64]>;

def MOVI1I32rr : InstTCE<(outs R32IRegs:$dst), (ins R1Regs:$src),
                     "$src -> $dst;",
                    []>;

def MOVI32I1rr : InstTCE<(outs R1Regs:$dst), (ins R32IRegs:$src),
                     "$src -> $dst;",
                    [(set R1Regs:$dst, (trunc R32IRegs:$src))]>;

def MOVI64I1ss : InstTCE<(outs R1Regs:$dst), (ins R64IRegs:$src),
                     "$src -> $dst;",
                    [(set R1Regs:$dst, (trunc R64IRegs:$src))]>, Requires<[Bitness64]>;

def MOVFI32rf : InstTCE<(outs R32IRegs:$dst), (ins R32FPRegs:$src),
	           "$src -> $dst;",
                   [(set R32IRegs:$dst, (bitconvert R32FPRegs:$src))]>;

def MOVIF32fr : InstTCE<(outs R32FPRegs:$dst), (ins R32IRegs:$src),
	           "$src -> $dst;",
                   [(set R32FPRegs:$dst, (bitconvert R32IRegs:$src))]>;

def MOVff : InstTCE<(outs FPRegs:$dst), (ins FPRegs:$src),
	           "$src -> $dst;",
                   []>;

def MOVFI64rf : InstTCE<(outs R64IRegs:$dst), (ins R64FPRegs:$src),
	           "$src -> $dst;",
                   [(set R64IRegs:$dst, (bitconvert R64FPRegs:$src))]>, Requires<[Bitness64]>;

def MOVIF64fr : InstTCE<(outs R64FPRegs:$dst), (ins R64IRegs:$src),
	           "$src -> $dst;",
                   [(set R64FPRegs:$dst, (bitconvert R64IRegs:$src))]>, Requires<[Bitness64]>;

def MOVsd : InstTCE<(outs R64IRegs:$dst), (ins R64DFPRegs:$src),
	           "$src -> $dst;",
                   [(set R64IRegs:$dst, (bitconvert R64DFPRegs:$src))]>, Requires<[Bitness64]>;

def MOVds : InstTCE<(outs R64DFPRegs:$dst), (ins R64IRegs:$src),
	           "$src -> $dst;",
                   [(set R64DFPRegs:$dst, (bitconvert R64IRegs:$src))]>, Requires<[Bitness64]>;


def MOVF64ff : InstTCE<(outs R64FPRegs:$dst), (ins R64FPRegs:$src),
	           "$src -> $dst;",
                   []>, Requires<[Bitness64]>;

def MOVF64dd : InstTCE<(outs R64DFPRegs:$dst), (ins R64DFPRegs:$src),
	           "$src -> $dst;",
                   []>, Requires<[Bitness64]>;



def MOVhh : InstTCE<(outs HFPRegs:$dst), (ins HFPRegs:$src),
	           "$src -> $dst;",
                   []>;

def MOVrh : InstTCE<(outs R32IRegs:$dst), (ins HFPRegs:$src),
	           "$src -> $dst;",
                   [(set R32IRegs:$dst, (bitconvert HFPRegs:$src))]>;

def MOVhr : InstTCE<(outs HFPRegs:$dst), (ins R32IRegs:$src),
	           "$src -> $dst;",
                   [(set HFPRegs:$dst, (bitconvert R32IRegs:$src))]>;

// Moves for guard RC <-> guard RC and guard RC <-> other RCs.
def MOVGrr : InstTCE<(outs GuardRegs:$dst), (ins GuardRegs:$src),
                 "$src -> $dst;", []>;

def MOVGI32rr : InstTCE<(outs R32IRegs:$dst), (ins GuardRegs:$src),
                    "$src -> $dst;", []>;

def MOVI32Grr : InstTCE<(outs GuardRegs:$dst), (ins R32IRegs:$src),
                    "$src -> $dst;", []>;

def MOVGI1rr : InstTCE<(outs R1Regs:$dst), (ins GuardRegs:$src),
                   "$src -> $dst;", []>;

def MOVI1Grr : InstTCE<(outs GuardRegs:$dst), (ins R1Regs:$src),
                   "$src -> $dst;", []>;
}


def NOP : InstTCE<(outs), (ins), "...;", []>;

// integer ops for floating point values - used for FP select emulation

def IORfff: InstTCE<(outs R32FPRegs:$dst), 
    (ins R32FPRegs:$src1, R32FPRegs:$src2), "", []>;

def IORhhh: InstTCE<(outs R32HFPRegs:$dst), 
    (ins R32HFPRegs:$src1, R32HFPRegs:$src2), "", []>;

def ANDfff: InstTCE<(outs R32FPRegs:$dst), 
    (ins R32FPRegs:$src1, R32FPRegs:$src2), "", []>;

def ANDhhh: InstTCE<(outs R32HFPRegs:$dst), 
    (ins R32HFPRegs:$src1, R32HFPRegs:$src2), "", []>;

def ADDfri: InstTCE<(outs R32FPRegs:$dst), 
    (ins R32IRegs:$src1, i32imm:$src2), "", []>;

def ADDhri: InstTCE<(outs R32HFPRegs:$dst), 
    (ins R32IRegs:$src1, i32imm:$src2), "", []>;

def SUBfir: InstTCE<(outs R32FPRegs:$dst), 
    (ins i32imm:$src1, R32IRegs:$src2), "", []>;

def SUBfri: InstTCE<(outs R32FPRegs:$dst), 
    (ins R32IRegs:$src1, i32imm:$src2), "", []>;

def SUBhir: InstTCE<(outs R32HFPRegs:$dst), 
    (ins i32imm:$src1, R32IRegs:$src2), "", []>;

def SUBhri: InstTCE<(outs R32HFPRegs:$dst), 
    (ins R32IRegs:$src1, i32imm:$src2), "", []>;

// (set R32IRegs:$dst, (zext R1Regs:$src))]>;

include "GenInstrInfo.td"

// ============================
//  Control flow
// ============================

// Return.
let isReturn = 1, isTerminator = 1, 
    hasDelaySlot = 1, isBarrier = 1 in {
    def RETL: InstTCE<(outs), (ins),
   	"return-address -> jump.1; # RETURN", [(retflag)]>;
}

// jump 
let isTerminator = 1, isBranch = 1, isBarrier = 1 in {
    def TCEBR : InstTCE<(outs), (ins i32imm:$dst), "$dst -> jump.1;", []>;

    let isIndirectBranch = 1 in {
        def TCEBRIND : InstTCE<(outs), (ins R32Regs:$dst), "$dst -> jump.1;", []>;
   }
}


// indirect branch
def: Pat<(brind (i32 R32Regs:$dst)),
         (TCEBRIND R32Regs:$dst)>;

// FP stores/loads

let mayLoad = 1 in {
    def LDWfr : InstTCE<(outs R32FPRegs:$op2),
        (ins MEMrr:$op1), "", [(set R32FPRegs:$op2,
        (load ADDRrr:$op1))]>, Requires<[BigEndian]>;

    def LDWfi : InstTCE<(outs R32FPRegs:$op2),
        (ins MEMri:$op1), "", [(set R32FPRegs:$op2,
        (load ADDRri:$op1))]>, Requires<[BigEndian]>;

    def LD32fr : InstTCE<(outs FPRegs:$op2),
        (ins MEMrr:$op1), "", [(set FPRegs:$op2,
        (load ADDRrr:$op1))]>, Requires<[LittleEndian]>;

    def LD32fi : InstTCE<(outs FPRegs:$op2),
        (ins MEMri:$op1), "", [(set FPRegs:$op2,
        (load ADDRri:$op1))]>, Requires<[LittleEndian]>;

    def LD64ds : InstTCE<(outs R64DFPRegs:$op2),
        (ins MEMrr:$op1), "", [(set R64DFPRegs:$op2,
        (load ADDRrr:$op1))]>, Requires<[Bitness64]>;

    def LD64da : InstTCE<(outs R64DFPRegs:$op2),
        (ins MEMri:$op1), "", [(set R64DFPRegs:$op2,
        (load ADDRri:$op1))]>, Requires<[Bitness64]>;

    def LD64fs : InstTCE<(outs R64FPRegs:$op2),
        (ins MEMrr:$op1), "", []>, Requires<[Bitness64]>;

    def LD64fa : InstTCE<(outs R64FPRegs:$op2),
        (ins MEMri:$op1), "", []>, Requires<[Bitness64]>;

    def LD64hs : InstTCE<(outs R64HFPRegs:$op2),(ins MEMrr:$op1), "",
        []>, Requires<[Bitness64]>;

    def LD64ha : InstTCE<(outs R64HFPRegs:$op2), (ins MEMri:$op1), "",
        []>,Requires<[Bitness64]>;

    def LD32hr : InstTCE<(outs R32HFPRegs:$op2),(ins MEMrr:$op1), "",
        []>, Requires<[LittleEndian]>;

    def LD32hi : InstTCE<(outs R64HFPRegs:$op2), (ins MEMri:$op1), "",
        []>,Requires<[LittleEndian]>;

    def LDWhr : InstTCE<(outs R32HFPRegs:$op2),(ins MEMrr:$op1), "",
        []>, Requires<[BigEndian]>;

    def LDWhi : InstTCE<(outs R64HFPRegs:$op2), (ins MEMri:$op1), "",
        []>,Requires<[BigEndian]>;
}

let mayStore = 1 in {
    def STWfr : InstTCE<(outs), (ins MEMrr:$op1, R32FPRegs:$op2), "",
        [(store R32FPRegs:$op2, ADDRrr:$op1)]>, Requires<[BigEndian]>;
    def STWfi : InstTCE<(outs), (ins MEMri:$op1, R32FPRegs:$op2), "",
        [(store R32FPRegs:$op2, ADDRri:$op1)]>, Requires<[BigEndian]>;

    def STHhr : InstTCE<(outs), (ins MEMrr:$op1, R32HFPRegs:$op2), "",
        [(store R32HFPRegs:$op2, ADDRrr:$op1)]>, Requires<[BigEndian]>;

    def STHhi : InstTCE<(outs), (ins MEMri:$op1, R32HFPRegs:$op2), "",
        [(store R32HFPRegs:$op2, ADDRri:$op1)]>, Requires<[BigEndian]>;

    def ST32fr : InstTCE<(outs), (ins MEMrr:$op1, FPRegs:$op2), "",
        [(store FPRegs:$op2, ADDRrr:$op1)]>, Requires<[LittleEndian]>;

    def ST32fi : InstTCE<(outs), (ins MEMri:$op1, FPRegs:$op2), "",
        [(store FPRegs:$op2, ADDRri:$op1)]>, Requires<[LittleEndian]>;

    def ST64ds : InstTCE<(outs), (ins MEMrr:$op1, R64DFPRegs:$op2), "",
        [(store R64DFPRegs:$op2, ADDRrr:$op1)]>, Requires<[Bitness64]>;

    def ST64da : InstTCE<(outs), (ins MEMri:$op1, R64DFPRegs:$op2), "",
        [(store R64DFPRegs:$op2, ADDRri:$op1)]>, Requires<[Bitness64]>;

    def ST16hr : InstTCE<(outs), (ins MEMrr:$op1, HFPRegs:$op2), "",
        [(store HFPRegs:$op2, ADDRrr:$op1)]>, Requires<[LittleEndian]>;

    def ST16hi : InstTCE<(outs), (ins MEMri:$op1, HFPRegs:$op2), "",
        [(store HFPRegs:$op2, ADDRri:$op1)]>, Requires<[LittleEndian]>;

        // The following ones used only for spills?
    def ST64hs : InstTCE<(outs), (ins MEMrr:$op1, R64HFPRegs:$op2), "",
        []>, Requires<[Bitness64]>;

    def ST64ha : InstTCE<(outs), (ins MEMri:$op1, R64HFPRegs:$op2), "",
        []>, Requires<[Bitness64]>;

    def ST64fs : InstTCE<(outs), (ins MEMrr:$op1, R64FPRegs:$op2), "",
        []>, Requires<[Bitness64]>;

    def ST64fa : InstTCE<(outs), (ins MEMri:$op1, R64FPRegs:$op2), "",
        []>, Requires<[Bitness64]>;

        // The following ones used only for spills?
    def ST32hr : InstTCE<(outs), (ins MEMrr:$op1, R32HFPRegs:$op2), "",
        []>, Requires<[LittleEndian]>;

    def ST32hi : InstTCE<(outs), (ins MEMri:$op1, R32HFPRegs:$op2), "",
        []>, Requires<[LittleEndian]>;

    def STWhr : InstTCE<(outs), (ins MEMrr:$op1, R32HFPRegs:$op2), "",
        []>, Requires<[BigEndian]>;

    def STWhi : InstTCE<(outs), (ins MEMri:$op1, R32HFPRegs:$op2), "",
        []>, Requires<[BigEndian]>;

}

// boolean store - big endian
def STQBrb : InstTCE<(outs), (ins MEMrr:$op1,R1Regs:$op2), "",
    [(truncstorei8 R1Regs:$op2, ADDRrr:$op1)]>, Requires<[BigEndian]>;

def PRED_TRUE_STQBrb : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,R1Regs:$op2), "", []>, Requires<[BigEndian]>;
def PRED_FALSE_STQBrb : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,R1Regs:$op2), "", []>, Requires<[BigEndian]>;
def STQBib : InstTCE<(outs), (ins MEMri:$op1,R1Regs:$op2), "", [(truncstorei8 R1Regs:$op2, ADDRri:$op1)]>, Requires<[BigEndian]>;
def PRED_TRUE_STQBib : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,R1Regs:$op2), "", []>, Requires<[BigEndian]>;
def PRED_FALSE_STQBib : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,R1Regs:$op2), "", []>, Requires<[BigEndian]>;

def STQBrj : InstTCE<(outs), (ins MEMrr:$op1,i1imm:$op2), "", [(truncstorei8 (i1 imm:$op2), ADDRrr:$op1)]>, Requires<[BigEndian]>;
def PRED_TRUE_STQBrj : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,i1imm:$op2), "", []>, Requires<[BigEndian]>;
def PRED_FALSE_STQBrj : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,i1imm:$op2), "", []>, Requires<[BigEndian]>;
def STQBij : InstTCE<(outs), (ins MEMri:$op1,i1imm:$op2), "", [(truncstorei8 (i1 imm:$op2), ADDRri:$op1)]>, Requires<[BigEndian]>;
def PRED_TRUE_STQBij : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,i1imm:$op2), "", []>, Requires<[BigEndian]>;
def PRED_FALSE_STQBij : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,i1imm:$op2), "", []>, Requires<[BigEndian]>;

def : Pat<(store R1Regs:$src, ADDRrr:$addr), (STQBrb ADDRrr:$addr, R1Regs:$src)>, Requires<[BigEndian]>;
def : Pat<(store R1Regs:$src, ADDRri:$addr), (STQBib ADDRri:$addr, R1Regs:$src)>, Requires<[BigEndian]>;

// boolean store - litte-endian
def ST8Brb : InstTCE<(outs), (ins MEMrr:$op1,R1Regs:$op2), "",
    [(truncstorei8 R1Regs:$op2, ADDRrr:$op1)]>, Requires<[LittleEndian]>;

def PRED_TRUE_ST8Brb : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,R1Regs:$op2), "", []>, Requires<[LittleEndian]>;
def PRED_FALSE_ST8Brb : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,R1Regs:$op2), "", []>, Requires<[LittleEndian]>;
def ST8Bib : InstTCE<(outs), (ins MEMri:$op1,R1Regs:$op2), "", [(truncstorei8 R1Regs:$op2, ADDRri:$op1)]>, Requires<[LittleEndian]>;
def PRED_TRUE_ST8Bib : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,R1Regs:$op2), "", []>, Requires<[LittleEndian]>;
def PRED_FALSE_ST8Bib : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,R1Regs:$op2), "", []>, Requires<[LittleEndian]>;

def ST8Brj : InstTCE<(outs), (ins MEMrr:$op1,i1imm:$op2), "", [(truncstorei8 (i1 imm:$op2), ADDRrr:$op1)]>, Requires<[LittleEndian]>;
def PRED_TRUE_ST8Brj : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,i1imm:$op2), "", []>, Requires<[LittleEndian]>;
def PRED_FALSE_ST8Brj : InstTCE<(outs), (ins GuardRegs:$pred, MEMrr:$op1,i1imm:$op2), "", []>, Requires<[LittleEndian]>;
def ST8Bij : InstTCE<(outs), (ins MEMri:$op1,i1imm:$op2), "", [(truncstorei8 (i1 imm:$op2), ADDRri:$op1)]>, Requires<[LittleEndian]>;
def PRED_TRUE_ST8Bij : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,i1imm:$op2), "", []>, Requires<[LittleEndian]>;
def PRED_FALSE_ST8Bij : InstTCE<(outs), (ins GuardRegs:$pred, MEMri:$op1,i1imm:$op2), "", []>, Requires<[LittleEndian]>;

def : Pat<(store R1Regs:$src, ADDRrr:$addr), (ST8Brb ADDRrr:$addr, R1Regs:$src)>, Requires<[LittleEndian]>;
def : Pat<(store R1Regs:$src, ADDRri:$addr), (ST8Bib ADDRri:$addr, R1Regs:$src)>, Requires<[LittleEndian]>;

// return address stack store/load
def STWRArr : InstTCE<(outs), (ins MEMrr:$op1,RAReg:$op2), "", [(store RAReg:$op2, ADDRrr:$op1)]>, Requires<[BigEndian]>;
def LDWRAr : InstTCE<(outs RAReg:$op2), (ins MEMrr:$op1), "", [(set RAReg:$op2, (load ADDRrr:$op1))]>, Requires<[BigEndian]>;

def ST32RArr : InstTCE<(outs), (ins MEMrr:$op1,RAReg:$op2), "", [(store RAReg:$op2, ADDRrr:$op1)]>, Requires<[LE32]>;
def LD32RAr : InstTCE<(outs RAReg:$op2), (ins MEMrr:$op1), "", [(set RAReg:$op2, (load ADDRrr:$op1))]>, Requires<[LE32]>;

def ST64RAss : InstTCE<(outs), (ins MEMrr:$op1,RAReg:$op2), "", [(store RAReg:$op2, ADDRrr:$op1)]>, Requires<[Bitness64]>;
def LD64RAs : InstTCE<(outs RAReg:$op2), (ins MEMrr:$op1), "", [(set RAReg:$op2, (load ADDRrr:$op1))]>, Requires<[Bitness64]>;


/* TODO: removed in the merge - or not? are these generated dynamically?
// 1-bit comparison with constant - xor or move.
// 1-bit one becomes -1 as i1 is signed, so the incoming imm is -1, not 1.
// do these comparisons both ways, reg first and imm first.
def : Pat<(i1 (setne R1Regs:$op1, (i1 -1))), (XORbicmp R1Regs:$op1, 1)>;
def : Pat<(i1 (setne (i1 -1), R1Regs:$op1)), (XORbicmp R1Regs:$op1, 1)>;
def : Pat<(i1 (seteq R1Regs:$op1, (i1 0))), (XORbicmp R1Regs:$op1, 1)>;
def : Pat<(i1 (seteq (i1 0), R1Regs:$op1)), (XORbicmp R1Regs:$op1, 1)>;
def : Pat<(i1 (setne R1Regs:$op1, (i1 0))), (MOVI1rr R1Regs:$op1)>;
def : Pat<(i1 (setne (i1 0), R1Regs:$op1)), (MOVI1rr R1Regs:$op1)>;
def : Pat<(i1 (seteq R1Regs:$op1, (i1 -1))), (MOVI1rr R1Regs:$op1)>;
def : Pat<(i1 (seteq (i1 -1), R1Regs:$op1)), (MOVI1rr R1Regs:$op1)>;
*/


//def : Pat<(i1 (setne (trunc R32IRegs:$op1), R1Regs:$op2)), (XORrb R1Regs:$op1, R1Regs:$op2)>, Requires<[Bitness32]>;
//def : Pat<(i1 (seteq (trunc R1Regs:$op1), R1Regs:$op2)), (XORbj (XORrb R32IRegs:$op1, R1Regs:$op2), 1)>, Requires<[Bitness32]>;
