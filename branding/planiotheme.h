/*
 * Copyright (C) by Planio GmbH
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

#ifndef PLANIO_THEME_H
#define PLANIO_THEME_H

#include "common/utility.h"
#include "common/version.h"
#include "theme.h"

#include <QColor>
#include <QString>

namespace OCC {

/**
 * @brief The PlanioTheme class
 * @ingroup libsync
 */
class PlanioTheme : public Theme
{
public:
    PlanioTheme() {};

    // Keep the historic lower-case config file name (the default would be
    // APPLICATION_EXECUTABLE ".cfg" = "PlanioStorage.cfg").
    QString configFileName() const override
    {
        return QStringLiteral("planiostorage.cfg");
    }

    QString helpUrl() const override
    {
        return QStringLiteral("https://pln.io/storage");
    }

    QColor wizardHeaderBackgroundColor() const override
    {
        return QColor(0x04, 0x42, 0x59);
    }

    QColor wizardHeaderTitleColor() const override
    {
        return QColor(Qt::white);
    }

    QString about() const override
    {
        return tr("<p>Version %1. For more information visit <a href=\"https://pln.io/storage\">plan.io</a></p>"
                  "<p><small>By Klaas Freitag, Daniel Molkentin, Olivier Goffart, Markus Götz, "
                  " Jan-Christoph Borchardt, Thomas Müller, Dominik Schmidt, Hannah von Reth, and others.</small></p>"
                  "<p>Copyright ownCloud GmbH</p>"
                  "<p>Distributed by %2 and licensed under the GNU General Public License (GPL) Version 2.0.<br/>"
                  "Planio and the Planio logo are registered trademarks of %2 in the "
                  "European Union, other countries, or both.</p>"
                  "<p><small>%3</small></p>")
            .arg(Utility::escape(Version::displayString()),
                Utility::escape(QStringLiteral(APPLICATION_VENDOR)),
                aboutVersions(Theme::VersionFormat::RichText));
    }

    QString oauthClientId() const override
    {
        return QStringLiteral("225b3709b9ac0af499a1439ea577baff3495a7a1354f87762b1390cc2cd66dcd");
    }

    QString oauthClientSecret() const override
    {
        return QStringLiteral("f52a5f6a26b24a3733d24e91f37914805a825a084f67ada3d3aa1f160440583b");
    }
};

}
#endif // PLANIO_THEME_H
