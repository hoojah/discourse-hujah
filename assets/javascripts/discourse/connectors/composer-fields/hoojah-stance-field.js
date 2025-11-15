export default {
  shouldRender(args, component) {
    const composer = args.model;
    return (
      composer &&
      composer.topic &&
      composer.topic.hoojah_poll &&
      composer.action === "reply"
    );
  },

  setupComponent(args, component) {
    // shouldRender is already called by Discourse, don't call it manually
    const composer = args.model;
    component.set("shouldShowStanceSelector",
      composer &&
      composer.topic &&
      composer.topic.hoojah_poll &&
      composer.action === "reply"
    );
  },

  actions: {
    setStance(stance) {
      const composer = this.args.model;
      if (composer) {
        composer.set("hoojahStance", stance);
      }
    },
  },
};
