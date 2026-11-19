// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "videoinfoextractor.h"

#include <QDebug>

#include "asyncytmusic.h"

VideoInfoExtractor::VideoInfoExtractor(QObject *parent)
    : QObject(parent)
{
    connect(this, &VideoInfoExtractor::videoIdChanged, this, [this] {
        if (m_videoId.isEmpty()) {
            m_videoInfo = {};
            m_audioFormats.clear();
            m_currentFormatIndex = 0;
            Q_EMIT songChanged();
            return;
        }

        setLoading(true);

        auto future = YTMusicThread::instance()->extractVideoInfo(QString::fromStdString(m_videoId.toStdString()));
        QCoro::connect(std::move(future), this, [this](const video_info::VideoInfo &videoInfo) {
            m_videoInfo = videoInfo;
            updateAudioFormats();
            setLoading(false);
            Q_EMIT songChanged();
        });
    });
}

void VideoInfoExtractor::updateAudioFormats()
{
    m_audioFormats.clear();
    m_currentFormatIndex = 0;

    if (m_videoInfo.formats.empty()) {
        return;
    }

    qWarning() << "available formats:";
    for (const auto &f : m_videoInfo.formats) {
        qWarning() << "  " << "acodec" << f.acodec << "format_id" << f.format_id << "quality" << f.quality << "vcodec" << f.vcodec;
    }

    // Filter audio only formats
    std::copy_if(m_videoInfo.formats.begin(), m_videoInfo.formats.end(), std::back_inserter(m_audioFormats),
        [](const video_info::Format &format) {
            return (!format.acodec.has_value() || format.acodec != "none") && format.vcodec == "none";
        });

    auto score = [](const video_info::Format &f) -> int {
        // High quality AAC HLS audio (format 234, ~134 kbps - unblocked by YouTube CDN bot protection)
        if (f.format_id == "234") return 1000;
        // Standard AAC HLS audio (format 233, ~48 kbps - unblocked)
        if (f.format_id == "233") return 900;
        // Direct M4A audio (format 139, ~48 kbps AAC - unblocked)
        if (f.format_id == "139") return 800;
        // Any other HLS manifest audio stream
        if (f.url.find("manifest.googlevideo.com") != std::string::npos || f.url.find(".m3u8") != std::string::npos) {
            return 700;
        }
        // Direct AAC (format 140)
        if (f.format_id == "140") return 600;
        // Direct Opus formats (251, 250, 249)
        if (f.format_id == "251") return 500;
        if (f.format_id == "250") return 400;
        if (f.format_id == "249") return 300;
        return f.quality.has_value() ? static_cast<int>(*f.quality * 10) : 0;
    };

    std::stable_sort(m_audioFormats.begin(), m_audioFormats.end(), [&](const auto &a, const auto &b) {
        int scoreA = score(a);
        int scoreB = score(b);
        if (scoreA != scoreB) {
            return scoreA > scoreB;
        }
        return a.quality.value_or(0) > b.quality.value_or(0);
    });

    if (m_audioFormats.empty()) {
        qWarning() << "No audio-only track found, falling back to worst-quality video";

        std::copy_if(m_videoInfo.formats.begin(), m_videoInfo.formats.end(), std::back_inserter(m_audioFormats), [](const video_info::Format &format) {
            return format.acodec != "none";
        });

        std::sort(m_audioFormats.begin(), m_audioFormats.end(), [](const video_info::Format &a, const video_info::Format &b) {
            return a.quality < b.quality;
        });
    }

    qWarning() << "Prioritized audio formats:";
    for (size_t i = 0; i < m_audioFormats.size(); ++i) {
        qWarning() << " [" << i << "] format_id:" << QString::fromStdString(m_audioFormats[i].format_id)
                   << "acodec:" << m_audioFormats[i].acodec
                   << "score:" << score(m_audioFormats[i]);
    }
}

QUrl VideoInfoExtractor::audioUrl() const
{
    if (m_videoId.isEmpty() || m_audioFormats.empty() || m_currentFormatIndex >= m_audioFormats.size()) {
        return {};
    }

    const auto &chosen = m_audioFormats[m_currentFormatIndex];
    qWarning() << "chosen audio url (index" << m_currentFormatIndex << "of" << m_audioFormats.size()
               << ", format_id" << QString::fromStdString(chosen.format_id) << "):"
               << QString::fromStdString(chosen.url);

    return QUrl(QString::fromStdString(chosen.url));
}

bool VideoInfoExtractor::tryNextFormat()
{
    if (m_currentFormatIndex + 1 < m_audioFormats.size()) {
        m_currentFormatIndex++;
        qWarning() << "Switching to fallback audio format index" << m_currentFormatIndex
                   << "format_id:" << QString::fromStdString(m_audioFormats[m_currentFormatIndex].format_id);
        Q_EMIT songChanged();
        return true;
    }
    qWarning() << "No more fallback audio formats available";
    return false;
}

QString VideoInfoExtractor::videoId() const
{
    return m_videoId;
}

void VideoInfoExtractor::setVideoId(const QString &videoId)
{
    if (m_videoId == videoId || videoId.isEmpty()) {
        return;
    }
    m_videoId = videoId;
    Q_EMIT videoIdChanged();
}

QString VideoInfoExtractor::title() const
{
    return QString::fromStdString(m_videoInfo.title);
}

QString VideoInfoExtractor::artist() const
{
    return QString::fromStdString(m_videoInfo.artist);
}

QString VideoInfoExtractor::album() const
{
    return QString::fromStdString(m_videoInfo.album);
}

QString VideoInfoExtractor::channel() const
{
    return QString::fromStdString(m_videoInfo.channel);
}

QString VideoInfoExtractor::thumbnail() const
{
    return QString::fromStdString(m_videoInfo.thumbnail);
}

bool VideoInfoExtractor::loading() const
{
    return m_loading;
}

void VideoInfoExtractor::setLoading(bool loading)
{
    m_loading = loading;
    Q_EMIT loadingChanged();
}
