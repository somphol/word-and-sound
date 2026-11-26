import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif
import WordAndSoundCore

exit(SelfTest.run() ? 0 : 1)
