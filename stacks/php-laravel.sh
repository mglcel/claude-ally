#!/bin/bash
# PHP Laravel Stack Detection Module
# Detects PHP Laravel projects and related frameworks

# Detect PHP Laravel projects
detect_php_laravel() {
    local project_dir="$1"
    local confidence=0
    local tech_stack="PHP Laravel"
    local project_type="web-app"

    # Check for Laravel indicators
    if [[ -f "$project_dir/composer.json" ]]; then
        confidence=$((confidence + 20))

        # Check for Laravel-specific dependencies
        if grep -q "laravel/framework\|laravel/laravel" "$project_dir/composer.json" 2>/dev/null; then
            confidence=$((confidence + 40))
            tech_stack="PHP Laravel + MySQL"
        elif grep -q "illuminate/" "$project_dir/composer.json" 2>/dev/null; then
            confidence=$((confidence + 30))
            tech_stack="PHP Laravel + MySQL"
        fi

        # Check for other PHP framework indicators
        if grep -q "symfony/\|doctrine/\|twig/" "$project_dir/composer.json" 2>/dev/null; then
            confidence=$((confidence + 20))
            if [[ ! "$tech_stack" == *"Laravel"* ]]; then
                tech_stack="PHP Symfony"
            fi
        fi

        # Check for WordPress indicators
        if grep -q "wordpress\|wp-" "$project_dir/composer.json" 2>/dev/null; then
            confidence=$((confidence + 30))
            tech_stack="PHP WordPress"
            project_type="cms"
        fi
    fi

    # Check for Laravel artisan command
    if [[ -f "$project_dir/artisan" ]]; then
        confidence=$((confidence + 30))
        tech_stack="PHP Laravel + MySQL"
    fi

    # Check for Laravel directory structure
    if [[ -d "$project_dir/app" && -d "$project_dir/config" && -d "$project_dir/resources" ]]; then
        confidence=$((confidence + 25))
        if [[ ! "$tech_stack" == *"Laravel"* ]]; then
            tech_stack="PHP Laravel + MySQL"
        fi
    fi

    # Check for PHP files in typical Laravel locations
    if [[ -f "$project_dir/app/Http/Kernel.php" || -f "$project_dir/config/app.php" ]]; then
        confidence=$((confidence + 30))
        tech_stack="PHP Laravel + MySQL"
    fi

    # Check for pure PHP project indicators
    if [[ -f "$project_dir/index.php" || -f "$project_dir/public/index.php" ]]; then
        confidence=$((confidence + 15))
        if [[ "$confidence" -lt 50 && ! "$tech_stack" == *"Laravel"* && ! "$tech_stack" == *"WordPress"* && ! "$tech_stack" == *"Symfony"* ]]; then
            tech_stack="PHP"
        fi
    fi

    # Check for database indicators
    if [[ -f "$project_dir/.env" ]] && grep -q "DB_\|DATABASE_" "$project_dir/.env" 2>/dev/null; then
        confidence=$((confidence + 10))
        if [[ "$tech_stack" == "PHP Laravel" ]]; then
            tech_stack="PHP Laravel + MySQL"
        elif [[ "$tech_stack" == "PHP" ]]; then
            tech_stack="PHP + MySQL"
        fi
    fi

    # Detect specific database types
    if [[ -f "$project_dir/composer.json" ]]; then
        if grep -q "doctrine/dbal\|illuminate/database" "$project_dir/composer.json" 2>/dev/null; then
            confidence=$((confidence + 10))
            if grep -q "mysql\|pdo_mysql" "$project_dir/composer.json" 2>/dev/null; then
                tech_stack="${tech_stack/+ MySQL/+ MySQL}"
            elif grep -q "postgresql\|pdo_pgsql" "$project_dir/composer.json" 2>/dev/null; then
                tech_stack="${tech_stack/+ MySQL/+ PostgreSQL}"
            elif grep -q "sqlite\|pdo_sqlite" "$project_dir/composer.json" 2>/dev/null; then
                tech_stack="${tech_stack/+ MySQL/+ SQLite}"
            fi
        fi
    fi

    # Return result if confidence is sufficient
    if [[ $confidence -ge 40 ]]; then
        echo "php-laravel|$tech_stack|$project_type|$confidence"
        return 0
    fi

    return 1
}

# Get patterns for PHP Laravel projects
get_php_laravel_patterns() {
    cat << 'EOF'
# 🚨 MANDATORY DEVELOPMENT REQUIREMENTS - NEVER SKIP THESE

## Security Patterns for PHP Laravel + MySQL
- **SQL Injection Prevention**: Always use Eloquent ORM or prepared statements, never raw SQL concatenation
- **XSS Protection**: Use Blade templating with automatic escaping, validate all user inputs
- **CSRF Protection**: Ensure all forms include @csrf tokens, validate in controllers
- **Authentication**: Use Laravel's built-in Auth system, implement proper password hashing
- **Authorization**: Use Gates and Policies for granular access control
- **Input Validation**: Use Form Requests or validate() method for all user inputs
- **File Upload Security**: Validate file types, use secure storage paths, prevent executable uploads
- **Environment Variables**: Store sensitive data in .env files, never commit secrets
- **Headers Security**: Implement security headers (CSP, HSTS, X-Frame-Options)
- **Rate Limiting**: Use Laravel's throttle middleware for API endpoints

## Performance Considerations for web-app
- **Database Optimization**: Use eager loading, query optimization, proper indexing
- **Caching Strategy**: Implement Redis/Memcached for sessions, queries, and views
- **Asset Optimization**: Use Laravel Mix for CSS/JS bundling and minification
- **Queue Management**: Use Laravel Queues for heavy operations (email, image processing)
- **CDN Integration**: Serve static assets through CDN for faster delivery
- **Database Connection Pooling**: Optimize connection management for high traffic
- **Opcache Configuration**: Enable and properly configure PHP Opcache
- **Session Optimization**: Use appropriate session drivers for scalability

## Error Handling Patterns
- **Exception Handling**: Use try-catch blocks and Laravel's exception handler
- **Logging Strategy**: Use Laravel's logging facade with appropriate channels
- **Debugging**: Use Laravel Telescope or Debugbar for development debugging
- **Error Pages**: Implement custom error pages for production environments
- **API Error Responses**: Standardize API error response formats
- **Validation Errors**: Return structured validation error responses

## Input Validation Requirements
- **Form Requests**: Create dedicated FormRequest classes for complex validation
- **API Validation**: Validate all API inputs with proper rules and messages
- **File Validation**: Validate file uploads (size, type, content)
- **Sanitization**: Sanitize inputs before database storage
- **Type Casting**: Use proper type casting in Eloquent models
- **Custom Rules**: Create custom validation rules for business logic
EOF
}

# Get critical assets for PHP Laravel projects
get_php_laravel_assets() {
    echo "user data, configuration files, database credentials, API keys, session data"
}

# Get common issues for PHP Laravel projects
get_php_laravel_issues() {
    echo "configuration errors, dependency issues, database migration problems, permission issues, cache conflicts"
}