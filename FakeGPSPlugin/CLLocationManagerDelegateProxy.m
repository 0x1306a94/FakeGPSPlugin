//
//  CLLocationManagerDelegateProxy.m
//  FakeGPS-Plugin
//
//  Created by king on 2019/8/2.
//

#import "CLLocationManagerDelegateProxy.h"

#import <CoreLocation/CoreLocation.h>

@interface CLLocationManagerDelegateProxy ()
@property (nonatomic, weak) id<CLLocationManagerDelegate> delegate;
@end

@implementation CLLocationManagerDelegateProxy
+ (instancetype)proxyWith:(id<CLLocationManagerDelegate>)delegate {
	CLLocationManagerDelegateProxy *proxy = [CLLocationManagerDelegateProxy alloc];
	NSLog(@"fake gps proxy: %@", delegate);
	proxy.delegate = delegate;
	return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
	if (self.delegate && [self.delegate respondsToSelector:sel]) {
		return [(NSObject *)self.delegate methodSignatureForSelector:sel];
	}
	return [super methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	if (self.delegate && [self.delegate respondsToSelector:invocation.selector]) {
		if (invocation.selector == @selector(locationManager:didUpdateLocations:)) {
			CLLocationDegrees latitude  = 35.680723;
			CLLocationDegrees longitude = 103.851502;

			CLLocation *loc = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];

			NSArray<CLLocation *> *locations = @[loc];
			[invocation setArgument:&locations atIndex:3];
		}
		[invocation setTarget:self.delegate];
		return;
	}
	return [super forwardInvocation:invocation];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return [self.delegate respondsToSelector:aSelector];
}

#pragma mark - <NSObject>

- (BOOL)isEqual:(id)object {
	return [self.delegate isEqual:object];
}

- (NSUInteger)hash {
	return [self.delegate hash];
}

- (Class)superclass {
	return [self.delegate superclass];
}

- (Class)class {
	return [self.delegate class];
}

- (BOOL)isKindOfClass:(Class)aClass {
	return [self.delegate isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
	return [self.delegate isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
	return [self.delegate conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
	return YES;
}

- (NSString *)description {
	return [self.delegate description];
}

- (NSString *)debugDescription {
	return [self.delegate debugDescription];
}
@end
