import Foundation

/// LRU Cache implementation using a combination of Dictionary and Doubly Linked List
public class LRUCache<Key: Hashable, Value> {
    
    // MARK: - Node Class for Doubly Linked List
    private class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    // MARK: - Properties
    private let capacity: Int
    private var cache: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    private let lock = NSLock() // For thread safety
    
    // MARK: - Initialization
    /// Creates an LRU Cache with the specified capacity
    /// - Parameter capacity: Maximum number of items the cache can hold
    public init(_ capacity: Int = 500) {
        self.capacity = max(capacity, 1) // Ensure at least capacity of 1
    }
    
    // MARK: - Public Methods
    
    /// Get value for a key, marking it as recently used
    /// - Parameter key: The key to look up
    /// - Returns: The value if exists, nil otherwise
    public func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = cache[key] else {
            return nil
        }
        
        // Move node to front (most recently used)
        moveToFront(node)
        return node.value
    }
    
    /// Set a key-value pair, evicting least recently used if needed
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: The key to associate with the value
    public func set(_ value: Value, for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        if let existingNode = cache[key] {
            // Update existing node
            existingNode.value = value
            moveToFront(existingNode)
        } else {
            // Create new node
            let newNode = Node(key: key, value: value)
            cache[key] = newNode
            addToFront(newNode)
            
            // Evict if over capacity
            if cache.count > capacity {
                evictLast()
            }
        }
    }
    
    /// Remove a key-value pair from the cache
    /// - Parameter key: The key to remove
    public func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = cache[key] else { return }
        removeNode(node)
        cache.removeValue(forKey: key)
    }
    
    /// Remove all items from the cache
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAll()
        head = nil
        tail = nil
    }
    
    /// Get all keys in the cache (ordered from most to least recently used)
    public var keys: [Key] {
        lock.lock()
        defer { lock.unlock() }
        
        var result: [Key] = []
        var current = head
        while let node = current {
            result.append(node.key)
            current = node.next
        }
        return result
    }
    
    /// Get all values in the cache (ordered from most to least recently used)
    public var values: [Value] {
        lock.lock()
        defer { lock.unlock() }
        
        var result: [Value] = []
        var current = head
        while let node = current {
            result.append(node.value)
            current = node.next
        }
        return result
    }
    
    /// Current number of items in the cache
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }
    
    // MARK: - Private Helper Methods
    
    private func addToFront(_ node: Node) {
        if head == nil {
            head = node
            tail = node
        } else {
            node.next = head
            head?.prev = node
            head = node
        }
    }
    
    private func removeNode(_ node: Node) {
        let prev = node.prev
        let next = node.next
        
        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        
        if let next = next {
            next.prev = prev
        } else {
            tail = prev
        }
        
        node.prev = nil
        node.next = nil
    }
    
    private func moveToFront(_ node: Node) {
        removeNode(node)
        addToFront(node)
    }
    
    private func evictLast() {
        guard let lastNode = tail else { return }
        removeNode(lastNode)
        cache.removeValue(forKey: lastNode.key)
    }
}

// MARK: - Convenience Extensions

extension LRUCache {
    /// Subscript access for easy get/set
    public subscript(key: Key) -> Value? {
        get {
            return get(key)
        }
        set {
            if let value = newValue {
                set(value, for: key)
            } else {
                remove(key)
            }
        }
    }
}

// MARK: - CustomStringConvertible for debugging
extension LRUCache: CustomStringConvertible where Key: CustomStringConvertible, Value: CustomStringConvertible {
    public var description: String {
        lock.lock()
        defer { lock.unlock() }
        
        var elements: [String] = []
        var current = head
        var index = 0
        while let node = current {
            elements.append("[\(index)]: \(node.key.description) -> \(node.value.description)")
            current = node.next
            index += 1
        }
        return "LRUCache(capacity: \(capacity), count: \(cache.count))\n" + elements.joined(separator: "\n")
    }
}
