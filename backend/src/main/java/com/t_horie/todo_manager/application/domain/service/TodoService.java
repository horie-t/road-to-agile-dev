package com.t_horie.todo_manager.application.domain.service;

import com.t_horie.todo_manager.adapter.in.web.Todo;
import com.t_horie.todo_manager.adapter.in.web.TodoRequest;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class TodoService {
    private final Map<Long, Todo> store = new ConcurrentHashMap<>();
    private final AtomicLong seq = new AtomicLong(0);

    public Collection<Todo> findAll() {
        return new ArrayList<>(store.values());
    }

    public Optional<Todo> findById(Long id) {
        return Optional.ofNullable(store.get(id));
    }

    public Todo create(TodoRequest req) {
        long id = seq.incrementAndGet();
        Instant now = Instant.now();
        Todo todo = new Todo(
                id,
                req.getTitle(),
                req.getDescription(),
                req.getCompleted() != null ? req.getCompleted() : false,
                now,
                now
        );
        store.put(id, todo);
        return todo;
    }

    public Optional<Todo> update(Long id, TodoRequest req) {
        Todo existing = store.get(id);
        if (existing == null) return Optional.empty();

        existing.setTitle(req.getTitle());
        existing.setDescription(req.getDescription());
        if (req.getCompleted() != null) {
            existing.setCompleted(req.getCompleted());
        }
        existing.setUpdatedAt(Instant.now());
        return Optional.of(existing);
    }

    public boolean delete(Long id) {
        return store.remove(id) != null;
    }
}
