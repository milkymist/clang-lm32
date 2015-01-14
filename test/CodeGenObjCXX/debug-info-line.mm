// RUN: %clang_cc1 -fcxx-exceptions -fexceptions -gline-tables-only -fblocks -emit-llvm %s -o - | FileCheck %s

void fn();

struct foo {
  ~foo();
};

void f1() {
  ^{
    foo f;
    fn();
    // CHECK: cleanup, !dbg [[DBG_F1:![0-9]*]]
#line 100
  }();
}

// CHECK-LABEL: define internal i8* @"\01-[TNSObject init]"
@implementation TNSObject
- (id)init
{
  foo f;
  fn();
  // CHECK: cleanup, !dbg [[DBG_TNSO:![0-9]*]]
#line 200
}
@end

// CHECK: [[DBG_F1]] = !{i32 100,
// CHECK: [[DBG_TNSO]] = !{i32 200,
