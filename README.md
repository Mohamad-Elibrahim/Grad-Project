# physical_therapy_clinic

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-blue?logo=flutter)](https://flutter.dev)
[![PHP](https://img.shields.io/badge/PHP-8.0+-purple?logo=php)](https://php.net)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql)](https://mysql.com)
[![License](https://img.shields.io/badge/License-MIT-green)](https://opensource.org/licenses/MIT)

A healthcare management system that allows patients to book therapy sessions and access rehabilitation services both in-center and at home,
 through mobile and web interfaces.
 Our graduation project for Computer Science degree.

## Key Features ✨
### For Patients
- 📅 Book in-clinic or at-home therapy sessions
- 👨‍⚕️ Filter therapists by specialty, gender & availability
- ⭐ Rate and review therapists
- 🔔 Appointment reminders by Calendar

### For Administrators
- 👥 Manage therapist profiles (add/update/delete)
- 📊 Monitor service utilization


## Technology Stack 🛠️
| Component          | Technology            |
|--------------------|-----------------------|
| **Frontend**       | Flutter (Dart)        |
| **Backend**        | PHP 8+                |
| **Database**       | MySQL 8               |
| **API**            | RESTful JSON API      |
| **Authentication** | JWT Token-based       |

## System Architecture 🏗️
```mermaid
graph LR
    A[Flutter Mobile App] --> B[PHP Backend]
    B --> C[MySQL Database]
    B --> D[External Services]