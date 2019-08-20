//
//  main.m
//  FakeGPS
//
//  Created by king on 2019/8/2.
//

#import "AppDelegate.h"
#import <UIKit/UIKit.h>

#import "jelbrekLib.h"
#include <mach/mach.h>

#if __LP64__
#define ADDR "%16lx"
#define IMAGE_OFFSET 0x2000
#else
#define ADDR "%8x"
#define IMAGE_OFFSET 0x1000
#endif

vm_address_t get_kernel_base(void);

int main(int argc, char *argv[]) {

//    mach_port_t tfp0;
//    kern_return_t kerr = host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 4, &tfp0);
//    if (kerr == KERN_SUCCESS) {
//        uint64_t kernelBase = get_kernel_base();
//        if (init_with_kbase(tfp0, kernelBase, NULL) == 0) {
//            init_jelbrek(tfp0);
//            rootify(getpid());
//        }
//    }

	@autoreleasepool {
		return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
	}
}

vm_address_t get_kernel_base(void) {
	kern_return_t ret;
	task_t kernel_task;
	vm_region_submap_info_data_64_t info;
	vm_size_t size;
	mach_msg_type_number_t info_count = VM_REGION_SUBMAP_INFO_COUNT_64;
	unsigned int depth                = 0;
	vm_address_t addr                 = 0x81200000;  // lowest possible kernel base address

	ret = task_for_pid(mach_task_self(), 0, &kernel_task);
	if (ret != KERN_SUCCESS)
		return 0;

	while (1) {
		// get next memory region
		ret = vm_region_recurse_64(kernel_task, &addr, &size, &depth, (vm_region_info_t)&info, &info_count);

		if (ret != KERN_SUCCESS)
			break;

		// the kernel maps over a GB of RAM at the address where it maps
		// itself so we use that fact to detect it's position
		if (size > 1024 * 1024 * 1024)
			return addr + IMAGE_OFFSET;

		addr += size;
	}

	return 0;
}
