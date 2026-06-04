//
//  helper.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/18/26.
//

#import "../Utils/Quaternion.h"
#import "../Utils/Vector3.h"

int count(int num) {
    int div = 1, num1 = num;
    while (num1 != 0) {
        num1 = num1 / 10;
        div = div * 10;
    }
    return div;
}
