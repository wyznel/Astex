//
//  DataCache.swift
//  Astex
//
//  Created by Ben Herbert on 21/08/2026.
//

import Foundation

class DataCache {
    static let shared = DataCache()
    
    private let cache = NSCache<NSString, AnyObject>()
    
    func set(_ value: Any, forKey key: String){
        cache.setObject(value as AnyObject, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> Any? {
        return cache.object(forKey: key as NSString)
    }
    
    func removeKey(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
