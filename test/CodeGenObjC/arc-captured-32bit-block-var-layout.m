// RUN: %clang_cc1 -fblocks -fobjc-arc -fobjc-runtime-has-weak -triple i386-apple-darwin -O0 -emit-llvm %s -o %t-64.s
// RUN: FileCheck --input-file=%t-64.s %s
// rdar://12184410

void x(id y) {}
void y(int a) {}

extern id opaque_id();

void f() {
    __weak id wid;
    __block int byref_int = 0;
    char ch = 'a';
    char ch1 = 'b';
    char ch2 = 'c';
    short sh = 2;
    const id bar = (id) opaque_id();
    id baz = 0;
    __strong id strong_void_sta;
    __block id byref_bab = (id)0;
    __block id bl_var1;
    int i; double dob;

// The patterns here are a sequence of bytes, each saying first how
// many sizeof(void*) chunks to skip (high nibble) and then how many
// to scan (low nibble).  A zero byte says that we've reached the end
// of the pattern.
//
// All of these patterns start with 01 3x because the block header on
// LP64 consists of an isa pointer (which we're supposed to scan for
// some reason) followed by three words (2 ints, a function pointer,
// and a descriptor pointer).

// Test 1
// block variable layout: BL_BYREF:1, BL_STRONG:3, BL_BYREF:1, BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [4 x i8] c"@2@\00" 
    void (^b)() = ^{
        byref_int = sh + ch+ch1+ch2 ;
        x(bar);
        x(baz);
        x((id)strong_void_sta);
        x(byref_bab);
    };    
    b();

// Test 2
// block variable layout: BL_BYREF:1, BL_STRONG:3, BL_WEAK:1, BL_BYREF:2, BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [5 x i8] c"@2PA\00"
    void (^c)() = ^{
        byref_int = sh + ch+ch1+ch2 ;
        x(bar);
        x(baz);
        x((id)strong_void_sta);
        x(wid);
        bl_var1 = 0;
        x(byref_bab);
    };    
}

@class NSString, NSNumber;
void g() {
  NSString *foo;
   NSNumber *bar;
   unsigned int bletch;
   __weak id weak_delegate;
  unsigned int i;
  NSString *y;
  NSString *z;
// block variable layout: BL_STRONG:2, BL_WEAK:1, BL_STRONG:2, BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [5 x i8] c"!1P1\00"
  void (^c)() = ^{
   int j = i + bletch;
   x(foo);
   x(bar);
   x(weak_delegate);
   x(y);
   x(z); 
  };
  c();
}

// Test 5 (unions/structs and their nesting):
void h() {
  struct S5 {
    int i1;
    __unsafe_unretained id o1;
    struct V {
     int i2;
     __unsafe_unretained id o2;
    } v1;
    int i3;
    union UI {
        void * i1;
        __unsafe_unretained id o1;
        int i3;
        __unsafe_unretained id o3;
    }ui;
  };

  union U {
        void * i1;
        __unsafe_unretained id o1;
        int i3;
        __unsafe_unretained id o3;
  }ui;

  struct S5 s2;
  union U u2;
  __block id block_id;

/**
block variable layout: BL_NON_OBJECT_WORD:1, BL_UNRETAINE:1, BL_NON_OBJECT_WORD:1, 
                       BL_UNRETAINE:1, BL_NON_OBJECT_WORD:3, BL_BYREF:1, BL_OPERATOR:0
*/
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [7 x i8] c" ` `\22@\00"
  void (^c)() = ^{
    x(s2.ui.o1);
    x(u2.o1);
    block_id = 0;
  };
  c();
}

// Test for array of stuff.
void arr1() {
  struct S {
    __unsafe_unretained id unsafe_unretained_var[4];
 } imported_s;

// block variable layout: BL_UNRETAINE:4, BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [2 x i8] c"c\00"
    void (^c)() = ^{
        x(imported_s.unsafe_unretained_var[2]);
    };    

   c();
}

// Test2 for array of stuff.
void arr2() {
  struct S {
   int a;
    __unsafe_unretained id unsafe_unretained_var[4];
 } imported_s;

// block variable layout: BL_NON_OBJECT_WORD:1, BL_UNRETAINE:4, BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [3 x i8] c" c\00"
    void (^c)() = ^{
        x(imported_s.unsafe_unretained_var[2]);
    };    

   c();
}

// Test3 for array of stuff.
void arr3() {
  struct S {
   int a;
    __unsafe_unretained id unsafe_unretained_var[0];
 } imported_s;

// block variable layout: BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [1 x i8] zeroinitializer
    void (^c)() = ^{
      int i = imported_s.a;
    };    

   c();
}


// Test4 for array of stuff.
@class B;
void arr4() {
  struct S {
    struct s0 {
      __unsafe_unretained id s_f0;
      __unsafe_unretained id s_f1;
    } f0;

    __unsafe_unretained id f1;

    struct s1 {
      int *f0;
      __unsafe_unretained B *f1;
    } f4[2][2];
  } captured_s;

/**
block variable layout: BL_UNRETAINE:3, 
                       BL_NON_OBJECT_WORD:1, BL_UNRETAINE:1, 
                       BL_NON_OBJECT_WORD:1, BL_UNRETAINE:1, 
                       BL_NON_OBJECT_WORD:1, BL_UNRETAINE:1, 
                       BL_NON_OBJECT_WORD:1, BL_UNRETAINE:1,
		       BL_OPERATOR:0
*/
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [10 x i8]
  void (^c)() = ^{
      id i = captured_s.f0.s_f1;
  };

   c();
}

// Test1 bitfield in cpatured aggregate.
void bf1() {
  struct S {
    int flag : 25;
    int flag1: 7;
    int flag2 :1;
    int flag3: 7;
    int flag4: 24;
  } s;

//  block variable layout: BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [1 x i8] zeroinitializer
  int (^c)() = ^{
      return s.flag;
  };
  c();
}

// Test2 bitfield in cpatured aggregate.
void bf2() {
  struct S {
    int flag : 1;
  } s;

// block variable layout: BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [1 x i8] zeroinitializer
  int (^c)() = ^{
      return s.flag;
  };
  c();
}

// Test3 bitfield in cpatured aggregate.
void bf3() {

     struct {
        unsigned short _reserved : 16;

        unsigned char _draggedNodesAreDeletable: 1;
        unsigned char _draggedOutsideOutlineView : 1;
        unsigned char _adapterRespondsTo_addRootPaths : 1;
        unsigned char _adapterRespondsTo_moveDataNodes : 1;
        unsigned char _adapterRespondsTo_removeRootDataNode : 1;
        unsigned char _adapterRespondsTo_doubleClickDataNode : 1;
        unsigned char _adapterRespondsTo_selectDataNode : 1;
        unsigned char _adapterRespondsTo_textDidEndEditing : 1;
        unsigned char _adapterRespondsTo_updateAndSaveRoots : 1;
        unsigned char _adapterRespondsTo_askToDeleteRootNodes : 1;
        unsigned char _adapterRespondsTo_contextMenuForSelectedNodes : 1;
        unsigned char _adapterRespondsTo_pasteboardFilenamesForNodes : 1;
        unsigned char _adapterRespondsTo_writeItemsToPasteboard : 1;
        unsigned char _adapterRespondsTo_writeItemsToPasteboardXXXX : 1;

        unsigned int _filler : 32;
    } _flags;

// block variable layout: BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [1 x i8] zeroinitializer
  unsigned char (^c)() = ^{
      return _flags._draggedNodesAreDeletable;
  };

   c();
}

// Test4 unnamed bitfield
void bf4() {

     struct {
        unsigned short _reserved : 16;

        unsigned char _draggedNodesAreDeletable: 1;
        unsigned char _draggedOutsideOutlineView : 1;
        unsigned char _adapterRespondsTo_addRootPaths : 1;
        unsigned char _adapterRespondsTo_moveDataNodes : 1;
        unsigned char _adapterRespondsTo_removeRootDataNode : 1;
        unsigned char _adapterRespondsTo_doubleClickDataNode : 1;
        unsigned char _adapterRespondsTo_selectDataNode : 1;
        unsigned char _adapterRespondsTo_textDidEndEditing : 1;

        unsigned long long : 64;

        unsigned char _adapterRespondsTo_updateAndSaveRoots : 1;
        unsigned char _adapterRespondsTo_askToDeleteRootNodes : 1;
        unsigned char _adapterRespondsTo_contextMenuForSelectedNodes : 1;
        unsigned char _adapterRespondsTo_pasteboardFilenamesForNodes : 1;
        unsigned char _adapterRespondsTo_writeItemsToPasteboard : 1;
        unsigned char _adapterRespondsTo_writeItemsToPasteboardXXXX : 1;

        unsigned int _filler : 32;
    } _flags;

//  block variable layout: BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [1 x i8] zeroinitializer
  unsigned char (^c)() = ^{
      return _flags._draggedNodesAreDeletable;
  };

   c();
}



// Test5 unnamed bitfield.
void bf5() {
     struct {
        unsigned char flag : 1;
        unsigned int  : 32;
        unsigned char flag1 : 1;
    } _flags;

//  block variable layout: BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [1 x i8] zeroinitializer
  unsigned char (^c)() = ^{
      return _flags.flag;
  };

   c();
}


// Test6 0 length bitfield.
void bf6() {
     struct {
        unsigned char flag : 1;
        unsigned int  : 0;
        unsigned char flag1 : 1;
    } _flags;

// block variable layout: BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [1 x i8] zeroinitializer
  unsigned char (^c)() = ^{
      return _flags.flag;
  };

   c();
}

// Test7 large number of captured variables.
void Test7() {
    __weak id wid;
    __weak id wid1, wid2, wid3, wid4;
    __weak id wid5, wid6, wid7, wid8;
    __weak id wid9, wid10, wid11, wid12;
    __weak id wid13, wid14, wid15, wid16;
    const id bar = (id) opaque_id();
//block variable layout: BL_STRONG:1, BL_WEAK:16, BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [3 x i8] c"0_\00"
    void (^b)() = ^{
      x(bar);
      x(wid1);
      x(wid2);
      x(wid3);
      x(wid4);
      x(wid5);
      x(wid6);
      x(wid7);
      x(wid8);
      x(wid9);
      x(wid10);
      x(wid11);
      x(wid12);
      x(wid13);
      x(wid14);
      x(wid15);
      x(wid16);
    };    
}


// Test 8 very large number of captured variables.
void Test8() {
__weak id wid;
    __weak id wid1, wid2, wid3, wid4;
    __weak id wid5, wid6, wid7, wid8;
    __weak id wid9, wid10, wid11, wid12;
    __weak id wid13, wid14, wid15, wid16;
    __weak id w1, w2, w3, w4;
    __weak id w5, w6, w7, w8;
    __weak id w9, w10, w11, w12;
    __weak id w13, w14, w15, w16;
    const id bar = (id) opaque_id();
// block variable layout: BL_STRONG:1, BL_WEAK:16, BL_WEAK:16, BL_WEAK:1, BL_OPERATOR:0
// CHECK: @"\01L_OBJC_CLASS_NAME_{{.*}}" = internal global [5 x i8]
    void (^b)() = ^{
      x(bar);
      x(wid1);
      x(wid2);
      x(wid3);
      x(wid4);
      x(wid5);
      x(wid6);
      x(wid7);
      x(wid8);
      x(wid9);
      x(wid10);
      x(wid11);
      x(wid12);
      x(wid13);
      x(wid14);
      x(wid15);
      x(wid16);
      x(w1);
      x(w2);
      x(w3);
      x(w4);
      x(w5);
      x(w6);
      x(w7);
      x(w8);
      x(w9);
      x(w10);
      x(w11);
      x(w12);
      x(w13);
      x(w14);
      x(w15);
      x(w16);
      x(wid);
    };  
}
