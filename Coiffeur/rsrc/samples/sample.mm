
//
//  sample.m
//  Coiffeur
//
//  Created by Anton Leuski on 4/1/15.
//


//Proin ut quam eros. Donec sed lobortis diam. Nulla nec odio lacus. Quisque porttitor egestas dolor in placerat. Nunc vehicula dapibus ipsum. Duis venenatis risus non nunc fermentum dapibus. Morbi lorem ante, malesuada in mollis nec, auctor nec massa. Aenean tempus dui eget felis blandit at fringilla urna ultrices. Suspendisse feugiat, ante et viverra lacinia, lectus sem lobortis dui, ultricies consectetur leo mauris at tortor. Nunc et tortor sit amet orci consequat semper. Nulla non fringilla diam.
//Fusce a metus eu diam varius congue nec nec sapien. Vestibulum orci tortor, sollicitudin ac euismod non, placerat ac augue. Nunc convallis accumsan justo. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec malesuada vehicula lectus, viverra sodales ipsum gravida nec. Integer gravida nisi ut magna mollis molestie. Nullam pharetra accumsan sagittis. Proin tristique rhoncus orci, eget vulputate nisi sollicitudin et. Quisque lacus augue, mollis non mollis et, ullamcorper in purus. Morbi et sem orci. Praesent accumsan odio in ante ullamcorper id pellentesque mauris rhoncus. Duis vitae neque dolor. Duis sed purus at eros bibendum cursus nec a nulla. Donec turpis quam, ultricies id pretium sit amet, gravida eget leo.

/*Proin ornare ligula eu tellus tempus elementum. Aenean bibendum iaculis mi, nec blandit lacus interdum vitae. Vestibulum non nibh risus, a scelerisque purus. Ut vel arcu ac tortor adipiscing hendrerit vel sed massa. Fusce sem libero, lacinia vulputate interdum non, porttitor non quam. Aliquam sed felis ligula. Duis non nulla magna.

Nullam eros mi, mollis in sollicitudin non, tincidunt sed enim. Sed et felis metus, rhoncus ornare nibh. Ut at magna leo. Suspendisse egestas est ac dolor imperdiet pretium. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam porttitor, erat sit amet venenatis luctus, augue libero ultrices quam, ut congue nisi risus eu purus. Cras semper consectetur elementum. Nulla vel aliquet libero. Vestibulum eget felis nec purus commodo convallis. Aliquam erat volutpat.
*/

#import <Foundation/Foundation.h>

void globalFunc();

namespace foo {
	class FooClass {
	public:
		FooClass();
		
		~FooClass();
		
	private:
		int var;
	};
}
@interface Foo {
@public
	int i;
}
@property int a;

- (id)init;
@end

@protocol Foo
@optional
@property int a;

- (id)init;
@end

@implementation Foo
@synthesize a;

void innerFunc() {
	auto la = [](int i1, int i2) -> bool mutable {
		return i1 < i2;
	}(1, 2);
}

int innerVar;

//Proin ut quam eros. Donec sed lobortis diam. Nulla nec odio lacus. Quisque porttitor egestas dolor in placerat. Nunc vehicula dapibus ipsum. Duis venenatis risus non nunc fermentum dapibus. Morbi lorem ante, malesuada in mollis nec, auctor nec massa. Aenean tempus dui eget felis blandit at fringilla urna ultrices. Suspendisse feugiat, ante et viverra lacinia, lectus sem lobortis dui, ultricies consectetur leo mauris at tortor. Nunc et tortor sit amet orci consequat semper. Nulla non fringilla diam.
- (id)init
{
	printf("Prime numbers: %d, %d, %d, %d, ...", 2, 3, 5, 7);
	return ^int(int n, int k) {
		return n + k;
	};
}
@end

// Spaces

#define min(a, b)  ((a) < (b) ? (a) : (b))

@interface Foo (Bar) : NSObject <Bar, Baz> {
@public
	int i;
@private
	id <Bar> bar;
}
- (id)from:(int)n with:(int)k andWith:(void*)p;

@property (readonly, getter=getParent) __weak Foo* parent;
@end

@implementation Foo
@synthesize parent, foo;

- (id)from:(int)n with:(int)k andWith:(void*)p
{
	void* s = (void*) @selector(foo:bar:);
	[[[Foo create:s with:42] init:p andWith:i] perform];
	[NSDictionary dictionaryWithObjectsAndKeys:@1, @"one", @222, @"twoTwoTwo", nil];
	return ^int(int n, int k) {
		return n + k;
	};
}
@end

typedef void(fn)(int i, int j, int k);

typedef void(^block)(int i, int j, int k);

typedef int X;

//Proin ut quam eros. Donec sed lobortis diam. Nulla nec odio lacus. Quisque porttitor egestas dolor in placerat. Nunc vehicula dapibus ipsum. Duis venenatis risus non nunc fermentum dapibus. Morbi lorem ante, malesuada in mollis nec, auctor nec massa. Aenean tempus dui eget felis blandit at fringilla urna ultrices. Suspendisse feugiat, ante et viverra lacinia, lectus sem lobortis dui, ultricies consectetur leo mauris at tortor. Nunc et tortor sit amet orci consequat semper. Nulla non fringilla diam.
int& refTest(X&& x) {
	int**& p = (int**&) x;
	int static& r = *&x;
	return r && (r & x) ? r : x;
}

void doSomething();

void doSomething(int a, int b, void* (*)()) {
	int i1 = 1 || 0 && 1;
	int i2 = i1 == !1 && i1 != 0;
	int i3 = 1 < 2 >= 3;
	int i4 = ~1 | 2 & 3 ^ 4;
	int i5 = ((1) + 2) - (4 * 5 / 6 % 7);
	int i6 = -1 << 2 >> -3;
	int i7 = 2 > 3 ? 7 + 8 + 9 : 11 + 12 + 13;
	int i8 = 2 < 3 + 7 + 8 + 9 ? : 11 + 12 + 13;
	void** p1 = &0;
	void* p2 = **p;
	int ii[3], jj[] = {1, 2, 3};
	id array = @[@1, @2];
	id dictionary = @{@1 : @"one", @222 : @"twoTwoTwo"};
	iiiii = jjjjj = kkkkk = mmmmm = 22222;
	
	(object.*method)();
	(pointer->*method)();
	auto la = [X, W](int i1, int i2) -> bool mutable {
		return i1 < i2;
	}(1, 2);
	
	doSomething(ii[1], jj[ii[2]], doSomething(123));
	
	if (1)doSomething(); else if (2)doSomething();
	if (1) {
		doSomething();
	} else if (2) {
		doSomething();
	} else doSomething();
	for (int i = 1, j = 2; i <= j; i++, j--)doSomethingElse();
	while (1)doSomethingElse();
	do doSomethingElse(); while (1);
	switch (1) {
		case 0:
			return;
		case 1: {
			return;
		}
	}
	
	@try {
		doSomethingElse();
	} @catch (NSException* e) {
		return;
	} @finally {
		return;
	}
	@synchronized (self) {
		doSomethingElse();
	}
	@autoreleasepool {
		doSomethingElse();
	}
}

struct foo {
	int i;
	char j;
} foo_t;

enum foo {
	i = 111, jjj = 222, kkkkk = 333
} foo_e;

namespace foo {
	class FooClass : BarClass, virtual BazClass {
	public:
		FooClass();
		
		virtual ~FooClass();
		
	private:
		int var;
	};
}

template <typename T, typename M>
inline T const& Min(T const& a, M const& b) {
	return a < b ? a : b;
}

template <typename T>
class list {
};

template <typename K, typename V = list <K>>
class hash {
};

template <class T>
struct FooT {
	hash <int, list <char>> elems;
	
	template <int N>
	int foo() {
		return N;
	}
	
	template <>
	int foo <2>() {
		return Min <>(1, 5);
	}
	
	list <int> mem = {1, 2, 3};
	float vector[3];
	
	FooT() : elems {{-1, {'c', 'p', 'p'}}, {1, {'j', 'b'}}}, vector {1f, 2f, 3f} {
	}
	
	FooT operator ++(int) volatile {
		return *this;
	};
	
	auto f(T t) -> decltype(t + doSomething()) {
		return t + doSomething();
	}
};

// Wrapping and Braces

#define min(a, b)  ((a) < (b) ? (a) : (b))

@interface Foo (Bar) : NSObject <Bar, Baz> {
@public
	int i;
@private
	id <Bar> bar;
}
- (id)from:(int)n with:(int)k andWith:(void*)p;

@property (readonly, getter=getParent) __weak Foo* parent;
@end

@implementation Foo
@synthesize parent, foo;

- (id)from:(int)n with:(int)k andWith:(void*)p
{
	void* s = (void*) @selector(foo:bar:);
	[[[Foo create:s with:42] init:p andWith:i] perform];
	[NSDictionary dictionaryWithObjectsAndKeys:@1, @"one", @222, @"twoTwoTwo", nil];
	return ^int(int n, int k) {
		return n + k;
	};
}
@end

typedef void(fn)(int i, int j, int k);

typedef void(^block)(int i, int j, int k);

typedef int X;

int& refTest(X&& x) {
	int**& p = (int**&) x;
	int static& r = *&x;
	return r && (r & x) ? r : x;
}

void doSomething();

void doSomething(int a, int b, void* (*)()) {
	int i1 = 1 || 0 && 1;
	int i2 = i1 == !1 && i1 != 0;
	int i3 = 1 < 2 >= 3;
	int i4 = ~1 | 2 & 3 ^ 4;
	int i5 = ((1) + 2) - (4 * 5 / 6 % 7);
	int i6 = -1 << 2 >> -3;
	int i7 = 2 > 3 ? 7 + 8 + 9 : 11 + 12 + 13;
	int i8 = 2 < 3 + 7 + 8 + 9 ? : 11 + 12 + 13;
	void** p1 = &0;
	void* p2 = **p;
	int ii[3], jj[] = {1, 2, 3};
	id array = @[@1, @2];
	id dictionary = @{@1 : @"one", @222 : @"twoTwoTwo"};
	iiiii = jjjjj = kkkkk = mmmmm = 22222;
	
	(object.*method)();
	(pointer->*method)();
	
	doSomething(ii[1], jj[ii[2]], doSomething(123));
	
	if (1)doSomething(); else if (2)doSomething();
	if (1) {
		doSomething();
	} else if (2) {
		doSomething();
	} else doSomething();
	for (int i = 1, j = 2; i <= j; i++, j--)doSomethingElse();
	while (1)doSomethingElse();
	do doSomethingElse(); while (1);
	switch (1) {
		case 0:
			return;
		case 1: {
			return;
		}
	}
	
	@try {
		doSomethingElse();
	} @catch (NSException* e) {
		return;
	} @finally {
		return;
	}
	@synchronized (self) {
		doSomethingElse();
	}
	@autoreleasepool {
		doSomethingElse();
	}
}

struct foo {
	int i;
	char j;
} foo_t;

enum foo {
	i = 111, jjj = 222, kkkkk = 333
} foo_e;

namespace foo {
	class FooClass
	: BarClass,
	virtual BazClass {
	public:
		FooClass();
		
		virtual ~FooClass();
		
	private:
		int var;
	};
}

template <typename T, typename M>
inline T const& Min(T const& a, M const& b) {
	return a < b ? a : b;
}

template <typename T>
class list {
};

template <typename K, typename V = list <K>>
class hash {
};

template <class T>
struct FooT {
	hash <int, list <char>> elems;
	
	template <int N>
	int foo() {
		return N;
	}
	
	template <>
	int foo <2>() {
		return Min <>(1, 5);
	}
	
	list <int> mem = {1, 2, 3};
	float vector[3];
	
	FooT()
	: elems {{-1, {'c', 'p', 'p'}}, {1, {'j', 'b'}}},
	vector {1f, 2f, 3f} {
		auto la = [=](int i1, int i2) -> bool mutable {
			return i1 < i2;
		}(1, 2);
	}
	
	auto f(T t) -> decltype(t + doSomething()) {
		return t + doSomething();
	}
};

// Blank Lines

#import <Foundation/Foundation.h>

void doSomething();

void doSomethingElse();

void global1;
void global2;

@interface Foo {
	int i;
	int j;
}
@property int a;
@property int b;

- (id)init;

- (void)doFoo;

@end

@implementation Foo
@synthesize x;
@dynamic y;
void innerGlobal1;
void innerGlobal2;

- (id)init
{
	printf("");
	return self;
}

- (void)doFoo
{
	int k = i + j;
	int m = k * 2;
}

@end

void doSomething() {
	int i = 1;
}

void doSomethingElse() {
	int i = 2;
}

namespace foo {
	class FooClass {
	public:
		FooClass();
		
		~FooClass();
		
	private:
		int var1;
		int var2;
	};
	
	class BarClass {
	};
}
namespace bar {
}

