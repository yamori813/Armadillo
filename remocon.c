/*
 *  remocon.c
 *  Armadillo
 *
 *  Created by H.M on 13/03/03.
 *  Copyright 2013 Hiroki Mori. All rights reserved.
 *
 * This code base on BtoIrRemoconMac.c
 *
 * 2013 KLab Inc.
 *
 * ビット・トレード・ワン社製「USB 接続赤外線リモコンキット」を操作する
 * Mac OS X 用 コンソールプログラム
 *
 * 同社製品ページ:
 * http://bit-trade-one.co.jp/BTOpicture/Products/005-RS/index.html
 *
 * ビルド方法:
 * gcc -Wall -g BtoIrRemoconMac.c -framework IOKit -framework CoreFoundation -o BtoIrRemoconMac
 *  - gcc 4.2.1 build 5666 (Xcode 3.2.6) でのビルドを確認
 *
 * HID Class Device Interfaces Guide - developer.apple.com
 * http://developer.apple.com/library/mac/#documentation/DeviceDrivers/Conceptual/HID/intro/intro.html
 *
 *
 * This software is provided "as is" without any express and implied warranty
 * of any kind. The entire risk of the quality and performance of this software
 * with you, and you shall use this software your own sole judgment and
 * responsibility. KLab shall not undertake responsibility or liability for
 * any and all damages resulting from your use of this software.
 * KLab does not warrant this software to be free from bug or error in
 * programming and other defect or fit for a particular purpose, and KLab does
 * not warrant the completeness, accuracy and reliability and other warranty
 * of any kind with respect to result of your use of this software.
 * KLab shall not be obligated to support, update or upgrade this software.  
 */

#include "remocon.h"

#include <stdio.h>
#include <unistd.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <CoreFoundation/CoreFoundation.h>

#define RECEIVE_WAIT_MODE_NONE  0
#define RECEIVE_WAIT_MODE_WAIT  1

#define DEVICE_BUFSIZE       65
#define REMOCON_DATA_LENGTH   7

static int g_readBytes;

IOHIDDeviceRef refDevice;

// 指定されたキーの整数プロパティを取得
int getIntProperty(IOHIDDeviceRef inIOHIDDeviceRef, CFStringRef inKey) {
    int val;
	if (inIOHIDDeviceRef) {
        CFTypeRef tCFTypeRef = IOHIDDeviceGetProperty(inIOHIDDeviceRef, inKey);
        if (tCFTypeRef) {
            if (CFNumberGetTypeID() == CFGetTypeID(tCFTypeRef)) {
                if (!CFNumberGetValue( (CFNumberRef) tCFTypeRef, kCFNumberSInt32Type, &val)) {
                    val = -1;
                }
            }
        }
    }
    return val;
}

// レポートのコールバック関数
static void reportCallback(void *inContext, IOReturn inResult, void *inSender,
                           IOHIDReportType inType, uint32_t inReportID,
                           uint8_t *inReport, CFIndex InReportLength)
{
    g_readBytes = InReportLength;
}

// デバイスからの読み込み
int ReadFromeDevice(IOHIDDeviceRef dev, unsigned char *buf, size_t bufsize, CFTimeInterval timeoutSecs)
{
    IOHIDDeviceRegisterInputReportCallback(dev,
										   &buf[1],
										   bufsize-1,
										   reportCallback,
										   NULL);
    g_readBytes = -1;
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeoutSecs, false);
    //printf("ReadFromeDevice: len=%d, 0=%X 1=%X 2=%X\n", g_readBytes, buf[0], buf[1], buf[2]);
    return g_readBytes;
}

// デバイスへの書き込み
IOReturn WriteToDevice(IOHIDDeviceRef dev, unsigned char *data, size_t len)
{
    IOReturn ret = IOHIDDeviceSetReport(dev, kIOHIDReportTypeOutput, data[0], data+1, len-1);
    if (ret != kIOReturnSuccess) {
        //printf("WriteToDevice: ret=0x%08X\n", ret);
    }
    return ret;
}

// リモコンデータ送信モード
void remocon_transfer(int len, int type, unsigned char *dat)
{
    unsigned char buf[DEVICE_BUFSIZE];
    
    memset(buf, 0xFF, sizeof(buf));
    buf[0] = 0;
    buf[1] = 0x60; // 送信指定    
    buf[2] = len << 4 | type;
    memcpy(buf+3, dat, (len * 4 + 4) / 8);

	for(int i = 0;i < 8; ++i) {
		printf("%02x ", buf[i]);
	}
	printf("\n");
	if (WriteToDevice(refDevice, buf, DEVICE_BUFSIZE) != kIOReturnSuccess) {
		fprintf(stderr, "WriteToDevice: err\n");
		goto DONE;
	}
    memset(buf, 0xFF, sizeof(buf));
    buf[0] = 0;
    buf[1] = 0x40; // デバイスの送信バッファをクリア
    WriteToDevice(refDevice, buf, DEVICE_BUFSIZE);
    memset(buf, 0x00, sizeof(buf));
    ReadFromeDevice(refDevice, buf, DEVICE_BUFSIZE, 0.5);
DONE:
    return;
}

int remocon_init()
{
    int vid, myVID = 0x22ea; // BTO IR REMOCON のベンダ ID
    int pid, myPID = 0x001e; // BTO IR REMOCON のプロダクト ID
    int i;
    IOReturn ret;
    unsigned char buf[65];
    IOHIDManagerRef refHidMgr = NULL;
    IOHIDDeviceRef *prefDevs = NULL;
    CFSetRef refDevSet = NULL;
    CFIndex numDevices;
    
    // HID マネージャリファレンスを生成
    refHidMgr = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    // すべての HID デバイスを対象とする
    IOHIDManagerSetDeviceMatching(refHidMgr, NULL);
    IOHIDManagerScheduleWithRunLoop(refHidMgr, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    // HID マネージャを開く
    IOHIDManagerOpen(refHidMgr, kIOHIDOptionsTypeNone);
    // マッチしたデバイス群のセットを得る
    refDevSet = IOHIDManagerCopyDevices(refHidMgr);
    numDevices = CFSetGetCount(refDevSet);
    prefDevs = malloc(numDevices * sizeof(IOHIDDeviceRef));
    // セットから値を取得
    CFSetGetValues(refDevSet, (const void **)prefDevs);
    
    // HID デバイス群を走査して BTO IR REMOCON を探す
    for (i = 0; i < numDevices; i++) {
        refDevice = prefDevs[i];
        // VID, PID をチェック
        vid = getIntProperty(refDevice, CFSTR(kIOHIDVendorIDKey)); 
        pid = getIntProperty(refDevice, CFSTR(kIOHIDProductIDKey));
        if (vid != myVID || pid != myPID) {
            refDevice = NULL;
            continue;
        }
        // デバイスのオープン
        ret = IOHIDDeviceOpen(refDevice, kIOHIDOptionsTypeNone);    
        if (ret != kIOReturnSuccess) {
            refDevice = NULL;
            continue;
        }
        // 試し打ち
        memset(buf, 0xFF, sizeof(buf));
        buf[0] = 0x00;
        buf[1] = 0x40;
        if (WriteToDevice(refDevice, buf, DEVICE_BUFSIZE) == kIOReturnSuccess) {
            memset(buf, 0, sizeof(buf));
            int bytes = ReadFromeDevice(refDevice, buf, DEVICE_BUFSIZE, 0.5);
            if (bytes >= 0 && buf[1] == 0x40) {
                break; // OK
            }
        }
        IOHIDDeviceClose(refDevice, kIOHIDOptionsTypeNone);
        refDevice = NULL;
    }
    if (!refDevice) {
        fprintf(stderr, "device not found\n");
        return 0;
    }
	
	return 1;
}

void remocon_close()
{
	IOHIDDeviceClose(refDevice, kIOHIDOptionsTypeNone);
}
