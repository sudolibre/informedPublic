//
//  imageStore.swift
//  informedPublic
//
//  Created by Jonathon Day on 2/8/17.
//  Copyright © 2017 dayj. All rights reserved.
//

import Foundation
import UIKit

class ImageStore {
    
    private let cache = NSCache<NSString, UIImage>()

    private func getImageURL(forKey key: String) -> URL {
        let imageDirectory: URL = {
            let directories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let directory = directories.first! //on iOS there will always be a value and only one
            return directory
        }()
        return imageDirectory.appendingPathComponent(key)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
        let imageURL = getImageURL(forKey: key)
        let imageData = UIImageJPEGRepresentation(image, 0.5)
        do {
        try imageData?.write(to: imageURL, options: .atomic)
        } catch {
           print(error.localizedDescription)
        }
    }
    
    func getImage(forKey key: String) -> UIImage? {
        let imageURL = getImageURL(forKey: key)

        if let image = cache.object(forKey: key as NSString) {
            return image
        } else if let imageData = try? Data(contentsOf: imageURL)  {
            let image = UIImage(data: imageData)
            return image
        } else {
            return nil
        }
    }
    
    func removeImage(forKey key: String) {
        let imageURL = getImageURL(forKey: key)
        cache.removeObject(forKey: key as NSString)
        try? FileManager.default.removeItem(at: imageURL)
    }
    
}
