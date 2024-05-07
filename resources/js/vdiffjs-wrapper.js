/*
 * vdiff.js - JavaScript-based visual differencing tool
 * http://codh.rois.ac.jp/software/vdiffjs/
 *
 * Copyright 2021 Center for Open Data in the Humanities, Research Organization of Information and Systems
 * Released under the MIT license
 *
 * Core contributor: Jun HOMMA (@2SC1815J)
 *
 * Licenses of open source libraries, see acknowledgements.md
 */
var VDiffWrapper = function(conf) {
    'use strict';

    var lng = getLang(conf);
    function getLang(config) {
        function getLangFromObject(obj) {
            if ($.isPlainObject(obj)) {
                if (obj.lang) { //陦ｨ遉ｺ險隱樊欠螳�
                    // lang: undefined 縺ｪ縺ｩ縺ｮ蝣ｴ蜷医�縲√％縺薙〒縺ｯ豎ｺ螳壹＠縺ｪ縺��
                    if (obj.lang !== 'ja') {
                        return 'en'; //ja莉･螟悶�蜈ｨ縺ｦen縺ｫfallback
                    } else {
                        return 'ja';
                    }
                }
            }
            return null;
        }
        //隨ｬ1蜆ｪ蜈茨ｼ哦ET繝代Λ繝｡繝ｼ繧ｿ
        var params_ = getParams(location.search);
        var lang = getLangFromObject(params_);
        //隨ｬ2蜆ｪ蜈茨ｼ夊ｨｭ螳壹ヵ繧｡繧､繝ｫ
        if (!lang) {
            lang = getLangFromObject(config);
        }
        //隨ｬ3蜆ｪ蜈茨ｼ壹ヶ繝ｩ繧ｦ繧ｶ縺ｮ險隱櫁ｨｭ螳�
        if (!lang) {
            lang = (String(window.navigator.language || window.navigator.userLanguage || 'ja').substring(0, 2) !== 'ja' ? 'en' : 'ja');
        }
        return lang;
    }
    function getParams(search) {
        var query = search.substring(1);
        if (query !== '') {
            var params = query.split('&');
            var paramsObj = {};
            for (var i = 0; i < params.length; i++) {
                var elems = params[i].split('=');
                if (elems.length > 1) {
                    var key = decodeURIComponent(elems[0].replace(/\+/g, ' '));
                    var val = decodeURIComponent(elems[1].replace(/\+/g, ' '));
                    paramsObj[key] = val;
                }
            }
            return paramsObj;
        } else {
            return null;
        }
    }
    function setupForm(params_) {
        var p = params_ || {};

        $form.addClass('vdiffjs-form-container').hide();

        var $form_ = $('<form>');

        var $img1Div = $('<div>');
        var $img1Url = $('<input>').attr('type', 'text').attr('name', 'img1').addClass('form-url');
        var $img1Label = $('<input>').attr('type', 'text').attr('name', 'img1_label').addClass('form-label');
        $img1Url.attr('placeholder', (lng !== 'ja') ? 'Image #1 URL' : '逕ｻ蜒�1 URL').val(('img1' in p) ? p.img1 : '');
        $img1Label.attr('placeholder', (lng !== 'ja') ? 'Image #1 Label (Optional)' : '逕ｻ蜒�1 繝ｩ繝吶Ν�井ｻｻ諢擾ｼ�').val(('img1_label' in p) ? p.img1_label : '');
        $img1Div.append($img1Url).append($img1Label);

        var $img2Div = $('<div>');
        var $img2Url = $('<input>').attr('type', 'text').attr('name', 'img2').addClass('form-url');
        var $img2Label = $('<input>').attr('type', 'text').attr('name', 'img2_label').addClass('form-label');
        $img2Url.attr('placeholder', (lng !== 'ja') ? 'Image #2 URL' : '逕ｻ蜒�2 URL').val(('img2' in p) ? p.img2 : '');
        $img2Label.attr('placeholder', (lng !== 'ja') ? 'Image #2 Label (Optional)' : '逕ｻ蜒�2 繝ｩ繝吶Ν�井ｻｻ諢擾ｼ�').val(('img2_label' in p) ? p.img2_label : '');
        $img2Div.append($img2Url).append($img2Label);

        var $submit = $('<button>').attr('type', 'submit').addClass('form-submit').text((lng !== 'ja') ? 'Compare' : '豈碑ｼ�☆繧�');

        $form.append($form_.append($img1Div).append($img2Div).append($submit));
        $('.vdiffjs-form-container input:text,.form-submit').button();
    }

    if (!$.isPlainObject(conf)) {
        conf = {};
    }
    var $wrapper = $('#' + conf.id);
    var viewerId = conf.id + '_vdiffjs_viewer';
    var formId   = conf.id + '_vdiffjs_form';
    var _viewerId = '#' + viewerId;
    var _formId = '#' + formId;
    $wrapper.addClass('vdiffjs-wrapper-container').append($('<div>').attr('id', viewerId)).append($('<div>').attr('id', formId));

    var $viewer = $(_viewerId);
    if ($.fn.spin) {
        $viewer.spin();
    }
    var $form = $(_formId).hide();
    var params = getParams(location.search);
    var config = {
        id: viewerId,
        size: {
            'max-size': 1500
        },
        lang: lng,
        doneCallback: function() {
            if (params) {
                if (params.img1_label && params.img2_label) {
                    $('title').text((lng !== 'ja') ?
                        'vdiff.js - comparison of ' + params.img1_label + ' and ' + params.img2_label :
                        'vdiff.js - ' + params.img1_label + '縺ｨ' + params.img2_label + '縺ｮ豈碑ｼ�');
                }
            }
            $form.hide();
        },
        failCallback: function() {
            var userAgent = window.navigator.userAgent.toLowerCase();
            if (userAgent.indexOf('msie') != -1 || userAgent.indexOf('trident') != -1 || typeof WebAssembly !== 'object') {
                //
            } else {
                setupForm(params);
                $form.show();
            }
        },
        alwaysCallback: function() {
            if ($.fn.spin) {
                $viewer.spin(false);
            }
        }
    };
    if (params && params.img1 && params.img2) {
        var params_ = [];
        params_.push('img1=' + encodeURIComponent(params.img1));
        params_.push('img2=' + encodeURIComponent(params.img2));
        if (params.img1_label) {
            params_.push('img1_label=' + encodeURIComponent(params.img1_label));
        }
        if (params.img2_label) {
            params_.push('img2_label=' + encodeURIComponent(params.img2_label));
        }
        if (params.corr_pts) {
            params_.push('corr_pts=' + encodeURIComponent(params.corr_pts));
        }
        if (params.img1_roi_xywh) {
            params_.push('img1_roi_xywh=' + encodeURIComponent(params.img1_roi_xywh));
        }
        if (params.mode) {
            params_.push('mode=' + encodeURIComponent(params.mode));
        }
        params_.push('lang=' + lng);

        var editorUrl = conf.editorUrl || 'editor.html';
        config.editorUrl = editorUrl + ((String(editorUrl).indexOf('?') > -1) ? '&' : '?') + params_.join('&');
    }
    VDiff(config);
};